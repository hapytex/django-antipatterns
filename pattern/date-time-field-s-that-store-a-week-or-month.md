% `Date`(`Time`)`Field`s that store a week or month
---
type: pattern
typefa: "fas fa-shapes"
tags: [datetime, date, week, query]
layers: [orm, model, model-fields]
related_packages: []
solinks:
- https://stackoverflow.com/q/68974578/67579
---

Sometimes we might want to specify a week in a certain month, such that
when we filter with a specific date, we look if that date is in the same
week as the one stored in the model.

We can solve this for example with an `IntegerField` and then determine
the number of weeks since a specific date, for example January 1<sup>st</sup>,
1990^[since the first week of 1990 starts on a Monday.].

The problem with such an `IntegerField` is that it takes a way a lot of
convenience to determine the week number. For example when filtering
for a specific week it requires that the programmer will need to convert
the datetime object to a week number. It will require a lot of logic
for example to join two items, or compare one week with a `date` object.

# What problems are solved with this?

In this pattern we will discuss an approach to define extra fields like a `WeekField`
and a `MonthField`. These fields will aim to implement querying in a *transparent*
manner. The model fields will truncate the `date`(`time`) object to the start of the
week or the month respectively, and also truncates the operands in case filtering is
done with these fields.

# What does this pattern look like?

Django's `DateField` is designed to store a given date. When creating a new
field, the two methods that one often has to implement are
[**<code>to_python(&hellip;)</code>**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.Field.to_python)
and [**<code>get_db_prep_value(&hellip;)</code>**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.Field.get_db_prep_value).
The first one is used to transform data from the database to its
Python counter part^[for example converting a JSON blob to Python objects.] whereas the latter is used to convert
items to their database counterpart. The <code>.get_db_prep_value(&hellip;)</code>
method will thus, for a `DateField` and `DateTimeField`, convert the `date` and `datetime`
objects to a certain format the specific database backend understands. For example `2021-09-04`.

What is interesting is that the <code>.get_db_prep_value(&hellip;)</code> method will call the
<code>.get_prep_value(&hellip;)</code> function that will, on its turn call the <code>.to_python(&hellip;)</code>
method. This thus means that both when serializing and serializing the data, the data is
passed through the <code>.to_python(&hellip;)</code> method. Indeed, we see this if we [inspect the source code&nbsp;<sup>[GitHub]</sup>](https://github.com/django/django/blob/stable/3.2.x/django/db/models/fields/__init__.py#L1264-L1272):

<blockquote><pre class="python"><code>class DateField(DateTimeCheckMixin, Field):
    # &hellip;

    def get_prep_value(self, value):
        value = super().get_prep_value(value)
        return self.<b>to_python(</b>value<b>)</b>

    def get_db_prep_value(self, value, connection, prepared=False):
        # Casts dates into the format expected by the backend
        if not prepared:
            value = self.<b>get_prep_value(</b>value<b>)</b>
        return connection.ops.adapt_datefield_value(value)</code></pre></blockquote>

We can make use of this by overriding the <code>.to_python(&hellip;)</code> method, and truncate
the `date`/`datetime` to the corresponding week, month, etc. We thus can work with a `DateTruncMixin` that
is implemented as:

<pre class="python"><code>class DateTruncMixin:

    def truncate_date(self, dt):
        return dt

    def to_python(self, value):
        value = super().to_python(value)
        if value is not None:
            return self.truncate_date(value)
        return value</code></pre>

we here thus make a mixin that will, in case the datetime is not `None` call the `truncate_date` which
by default does not truncate.

With this mixin, we can implement fields that truncate like a `WeekField` and a `MonthField`. In
this example a week starts on *Monday*:

<pre class="python"><code>from datetime import timedelta
from django.db.models import DateField

class WeekField(DateTruncMixin, DateField):
    
    def truncate_date(self, dt):
        return dt - timedelta(days=dt.weekday())


class MonthField(DateTruncMixin, DateField):

    def truncate_date(self, dt):
        return dt - timedelta(days=dt.day-1)</code></pre>

The same logic can be applied for `DateTimeField`s:

<pre class="python"><code>from django.db.models import DateTimeField

class MinuteField(DateTruncMixin, DateTimeField):
    
    def truncate_date(self, dt):
        return dt.replace(second=0, microsecond=0)


class HourField(DateTruncMixin, DateTimeField):

    def truncate_date(self, dt):
        return dt.replace(minute=0, second=0, microsecond=0)</code></pre>


Now we can thus implement variants for a `WeekField`, `MonthField`, `QuarterField`, 'SeasonField', etc.
The idea is that we can use this for querying, creating, and updating values in a model that uses
such field.

We can for example make a simple `Week` model with a `WeekField`:

<pre class="python"><code>from django.db import models

class Week(models.Model):
    week = WeekField(unique=True)</code></pre>

Now we can start creating `Week` objects. If we create the same `Week` object
twice with [**<code>.get_or_create(&hellip;)</code>**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/querysets/#get-or-create),
then the second time it will use the old `Week` object, even if we query
with another `date` of the same week, it will retrieve the `Week` object
created by the first creation call. We can for example use two dates of the 35<sup>th</sup>
week of 2021:

```pycon
>>>> Week.objects.get_or_create(week='2021-09-04')
(<Week: Week object (1)>, True)
>>> Week.objects.get_or_create(week='2021-08-31')
(<Week: Week object (1)>, False)
```

In the database the date is stored as `2021-08-30`:

```sql
mysql> SELECT * FROM week;
+----+------------+
| id | week       |
+----+------------+
|  1 | 2021-08-30 |
+----+------------+
1 row in set (0.00 sec)
```

We thus can also compare two `WeekField`s effectively
to check if they point to the same week. If for example
our `Week` model would have a second field `week2`, then
we can filter with `Week.objects.filter(week=F('week2'))`
to check if the two fields are equivalent.

We can also retrieve the `Week` object we created with
the start of the week as value for the `week` attribute:

```pycon
>>> week = Week.objects.get(pk=1)
>>> week.week
datetime.date(2021, 8, 30)
```

If we change the `week` to another `date` object, and save
the object again, it is updated to the start of the week
of that date object. If we query for the old week, then we
do not get any object:

```pycon
>>> from datetime import date
>>> week.week = date(2021, 9, 8)
>>> week.save()
>>> Week.objects.get(week='2021-9-6')
<Week: Week object (1)>
>>> Week.objects.filter(week='2021-09-04')
<QuerySet []>
```

There are still some issues when comparing the value for a `WeekField`
with the value of a `DateField` for example, since the `WeekField` is,
behind the curtains, just a `DateField` that is set to the beginning
of the week. We however think that the fields defined above
will result in more programmer convenience.
