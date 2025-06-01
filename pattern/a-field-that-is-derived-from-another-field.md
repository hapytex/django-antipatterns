% A field that is derived from another field
---
type: pattern
typefa: "fas fa-shapes"
tags: [fields, derived-field]
layers: [models]
related_packages: []
solinks: []
---

# What problems are solved with this?

It is usually *not* a good idea to have two or more columns in the database where the value of one column is derived from other column(s). In some cases, it might not be possible to do this in a different way, or the derived column is used by another tool. In that case, we can work use the [**`.pre_save(…)`** method](https://docs.djangoproject.com/en/5.2/ref/models/fields/#django.db.models.Field.pre_save) which runs just before the model record(s) are saved, and therefore thus guarantee that the column is in sync with the columns it depends on. It can however not work cross-table.

# What does this pattern look like?

In this particular case, We had to make a field that for another field named `date`, populated a field named `month` with the month represented as an integer with the year and month.

We can do this by creating a subclass of a [**`PositiveIntegerField`**](https://docs.djangoproject.com/en/stable/ref/models/fields/#positiveintegerfield) that then overrides the `.pre_save(…)` method as follows:

```python3
from django.db import models


class AutoMonthField(models.PositiveIntegerField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('editable', False)
        kwargs.setdefault('null', True)
        kwargs.setdefault('default', None)

    def pre_save(self, model_instance, add):
        date = model_instance.date
        value = None
        if date is not None:
            value = date.year * 100 + date.month
        setattr(model_instance, self.attname, value)
        return value
```

We can then inject this field into model with a field `.date`, like:

```python3
from django.db import models


class MyModel(models.Model):
    date = models.DateField()
    month = AutoMonthField()
```

The `month` field is here non-editable, since it thus derives the value from the `.date` field, and will, each time we save a `MyModel` object, look at the `.date` field, and adapt accordingly.

# Extra tips

We can encapsulate the above logic in mixin that looks like this:

```python3
class AutoFieldMixin:
    def __init__(self, *args, function=None, **kwargs):
        kwargs.setdefault('editable', False)
        self.function = function
        super().__init__(*args, **kwargs)

    def determine_value(self, model_instance, add):
        return self.function(model_instance, add)

    def pre_save(self, model_instance, add):
        value = self.determine_value(model_instance, add)
        setattr(model_instance, self.attname, value)
        return self.get_prep_value(value)

    def deconstruct(self):
        name, path, args, kwargs = super().deconstruct()
        kwargs.pop('function', None)
        return name, path, args, kwargs
```

and for example work with:

```python3
from django.db import models


class AutoMonthField(AutoFieldMixin, models.PositiveIntegerField):
    def determine_value(self, model_instance, add):
        date = model_instance.date
        if date is not None:
            return date.year * 100 + date.month
```

This will normally work for [`.bulk_create(…)`](https://docs.djangoproject.com/en/stable/ref/models/querysets/#bulk-create), and [`.bulk_update(…)`](https://docs.djangoproject.com/en/stable/ref/models/querysets/#bulk-update) if you specify the `month` field as field to update. But this will not update the `month` field, if you use [`.update(date=my_date)`](https://docs.djangoproject.com/en/stable/ref/models/querysets/#update)
