% A default record per entity
---
type: pattern
typefa: "fas fa-shapes"
tags: [default, default-record]
layers: [models, orm]
related_packages: []
solinks: [https://stackoverflow.com/q/79635695/67579]
---

# What problems are solved with this?

It occurs often that a certain entity, a `User`, a `Company`, etc. has a list of items, with one item being the default one. For example a `User` could have different `Setting`s, with (at most) one `Setting` being the default one, or a `Company` that has multiple names, but one official one. We want to ensure there as at most *one* such default record, and a more efficient way to retrieve that record.

# What does this pattern look like?

First we make a model to store the corresponding `Setting`s or `CompanyName`s with a `BooleanField()` that indicates if the item is the default, for example:

```
from django.conf import settings
from django.db import models

class UserSetting(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )
    is_default = models.BooleanField(default=False)
    # …
```

We can enforce at the database level that there is *at most* one such element with a [**`UniqueConstraint`**](https://docs.djangoproject.com/en/stable/ref/models/constraints/#uniqueconstraint), this constraint makes the `user` unique, with as condition that `is_default` is `True`, like:

```
from django.conf import settings
from django.db import models
from django.db.models import Q


class UserSetting(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )
    is_default = models.BooleanField(default=False)
    # …

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=('user',),
                condition=Q(is_default=True),
                name='one_default_setting_per_user'
            )
        ]
```

This now ensures there is at most one default. But this would require making an extra query to retrieve the default setting for a user. Indeed, for `some_user`, we would query with:

```
user_settings = some_user.usersetting_set.get(is_default=True)
```

this will then either retrieve the `UserSetting` record, or raise a [**`UserSetting.DoesNotExist`**](https://docs.djangoproject.com/en/stable/ref/models/class/#django.db.models.Model.DoesNotExist) exception, if no such record exists. It can *not* raise a [**`UserSetting.MultipleObjectsReturned`**](https://docs.djangoproject.com/en/stable/ref/models/class/#multipleobjectsreturned) exception, unless the database does not enforce the constraint, since there is always at most one default setting *per* item.

But this still requires to make a query *per* `User`, which might not be efficient if we have to render the settings of all users immediately. We can work with a `FilteredRelation` for this, indeed:

```
from django.db.models import 

users = User.objects.annotate(
    default_setting=FilteredRelation(
        'usersetting',
        condition=Q(usersetting__is_default=True)
    ),
).select_related('default_setting')
```

This will add an extra attribute `.default_setting` to the `User` objects arising from the `QuerySet`, which is a `UserSetting` object with thus the settings for that user. If no `UserSetting` exists, it has no such attribute.

So we can enumerate over the `users`, and check if such attribute exists with:

```
for user in users:
    try:
        setting = user.default_setting
    except AttributeError:
        setting = None
```

we thus fetch all the default settings in bulk, and can then post-process these.

# Extra tips

## What if we want only one default record for the entire table?

In that case, we can set the field that is unique, to `is_default` itself, like:

```
class GlobalSetting(models.Model):
    is_default = models.BooleanField(default=True)
    # …

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=('is_default',),
                condition=Q(is_default=True),
                name='one_global_default_setting'
            )
        ]
```
