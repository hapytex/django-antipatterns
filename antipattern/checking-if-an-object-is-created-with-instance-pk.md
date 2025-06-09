% Checking if an object is created with instance.pk
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [database, create]
layers: [models, views]
related_packages: []
solinks: [https://stackoverflow.com/questions/79658640/how-do-i-prevent-a-user-from-creating-multiple-objects-within-24-hours-in-django/]
---

A lot of code checks if an object is saved as an update, or created with a check of the truthiness of `instance.pk`, for example:

```python3
from django.db import models

class MyModel(models.Model):
    # ...

    def save(self, *args, **kwargs):
        if self.pk:
            print('updating')
        else:
            print('creating')
        return super().save(*args, **kwargs)
```

# Why is it a problem?

Because if the primary key field constructs a default value itself, `self.pk` will contain that value, and therefore the check no longer works.

A popular example of this is when `MyModel` has `UUIDField` as primary key. For example:

```python3
from django.db import models
import uuid

class MyModel(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    # …
```

If we now create an object without saving it in the database, it will already have a UUID:

```
>>> my_model = MyModel()
>>> my_model.id
UUID('c4e8412a-7ec0-419d-b34c-c0bafb67ff49')
```

so now the check will fail.

# What can be done to resolve the problem?

We can work with `instance._state.adding` instead, like:

```python3
from django.db import models

class MyModel(models.Model):
    # …

    def save(self, *args, **kwargs):
        if self._state.adding:
            print('creating')
        else:
            print('updating')
        return super().save(*args, **kwargs)
```

This will determine how we got to this `MyModel` object: from the database, or by creating a model object. This however does not say that a record with the primary key does not exists at the database level already.

Indeed, `MyModel(pk=1)._state.adding` will also say `True`, even if a record with `id=1` already exists at the database level. If we want to know for sure such record exists in the database, there is not much else we can do but making a query and asking the database.
