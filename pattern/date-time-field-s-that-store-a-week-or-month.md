% `Date(Time)Field`s that store a week or month
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
the number of weeks since a specific date, for example January 1<sup>st</sup>, 1990^[since the first week of 1990 starts on a monday.].

The problem with such an `IntegerField` is that it takes a way a lot of
convenience to determine the week number. For example when filtering
for a specific week it requires that the programmer will need to convert
the datetime object to a week number. It will require a lot of logic
for example to join two items, or compare one week with a `date` object.

# What problems are solved with this?

In this pattern we will discuss an approach to define two extra fields: a `WeekField`
and a `MonthField`. These fields will aim to implement querying in a *transparent*
manner. The model fields will truncate the `date`(time) object to the start of the
week or the month respectively, and also truncates the operands in case filtering is
done with the `WeekField` or `MonthField`.

# What does this pattern look like?

Django's `DateField` is designed to store a given date. When creating a new
field, the two methods that one often has to implement are
[**<code>to_python(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.Field.to_python)
and [**<code>get_db_prep_value(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.Field.get_db_prep_value).
The first one is used to transform data from the database to its
Python counter part^[for example converting a JSON blob to Python objects.] whereas the latter is used to convert
items to their database counterpart. The <code>.get_db_prep_value(&hellip;)</code>
method will thus, for a `DateField` and `DateTimeField`, convert the `date` and `datetime`
objects to a certain format the specific database backend understands. For example `2021-09-04`.

What is intersting is that the <code>.get_db_prep_value(&hellip;)</code> method will call the
<code>.get_prep_value(&hellip;)</code> function that will, on its turn call the <code>.to_python(&hellip;)</code>
method. This thus means that both when serializing and deserialzing the data, the data is
passed through the <code>.to_python(&hellip;)</code> method. Indeed, we see this if we [inspect the source code [GitHub]](https://github.com/django/django/blob/stable/3.2.x/django/db/models/fields/__init__.py#L1264-L1272):

<blockquote><pre class="python3"><code>class DateField(DateTimeCheckMixin, Field):
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

<pre class="python3"><code>class DateTruncMixin:

    def truncate_date(self, dt):
        return dt

    def to_python(self, value):
        value = super().to_python(value)
        if value is not None:
            return self.truncate_date(value)
        return value</code></pre>

we here thus make a mixin that will, in case the datetime is not `None` call the `truncate_date` which
by default does not truncate.

With this mixin, we can however implement fields that truncate like a `WeekField` and a `MonthField`:

<pre class="python3"><code>from datetime import timedelta
from django.db.models import DateField

class WeekField(DateTruncMixin, DateField):
    
    def truncate_date(self, dt):
        return dt - timedelta(days=dt.weekday())


class MonthField(DateTruncMixin, DateField):

    def truncate_date(self, dt):
        return dt - timedelta(days=dt.day-1)</code></pre>

The same logic can be applied for `DateTimeField`s:

<pre class="python3"><code>from django.db.models import DateTimeField

class MinuteField(DateTruncMixin, DateTimeField):
    
    def truncate_date(self, dt):
        return dt.replace(second=0, microsecond=0)


class HourField(DateTruncMixin, DateTimeField):

    def truncate_date(self, dt):
        return dt.replace(minute=0, second=0, microsecond=0)</code></pre>


Now we can thus implement variants for a `WeekField`, `MonthField`, `QuarterField`, 'SeasonField', etc.
The idea is that we can use this for querying, creating, and updating values in a model that uses
such field.
