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
and [**<code>get_prep_value(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.Field.get_prep_value).
The first one is used to transform data from the database to its
Python counter part^[for example converting a JSON blob to Python objects.] whereas the latter is used to convert
items to their database counterpart. For example by formatting
the date in a format the database understands.
