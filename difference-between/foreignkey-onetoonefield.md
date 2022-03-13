% ForeignKey and OneToOneField
---
type: difference-between
typefa: "fas fa-adjust"
tags: [foreignkey, onetoonefield, database]
layers: models
related_packages: []
solinks: []
---

The Django model field API provides a [**`ForeignKey`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#foreignkey) and a [**`OneToOneField`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.OneToOneField). Both fields share most of the same parameters: in fact a `OneToOneField` is a subclass of a `ForeignKey`. In the constructor, it sets the [**<code>unique=&hellip;</code>** parameter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#unique) to `True`. If you create a `ForeignKey` with `unique=True`, then Django will raise an warning that explains that a `OneToOneField` is probably more appropriate. The fact that a `OneToOneField` is unique means thus that for two records, the `OneToOneField`s can *not* refer to the same record.

As a result if a `Profile` has a `OneToOneField` to a `User` model, it means that two `Profile`s can not refer to the same `User`, and thus a `User` record has *at most* one related `Profile`. This is important: it means that if we access the `Profile`(s) of a `User` we get zero or one records. As a result the designers of Django specified the [**<code>related_name=&hellip;</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.ForeignKey.related_name) of a `OneToOneField`, not as <code><i>modelname</i>_set</code>, but <code><i>modelname</i></code>. Indeed, you access the `Profile` that belongs to a `User` object `my_user` with `my_user.profile` (given you do not override the <code>related_name=&hellip;</code> parameter). This will look for a `Profile` object, and returns that object if it can be found, otherwise it raises a `RelatedObjectDoesNotExist` exception. For a `ForeignKey`, the default would have been `profile_set`, and `my_user.profile_set` is a [**`RelatedManager`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/relations/#django.db.models.fields.related.RelatedManager): accessing this attribute would thus never raise an error, and one can then access all the related `Profile`s with `my_user.profile_set.all()`.

A `OneToOneField` is also used for inheritance. If one has a *concrete* model named `Vehicle`, and a subclass of that model named `Car`, then Django will add a "hidden" `OneToOneField` named <code><i>modename</i>_ptr</code> with <code><i>modelname</i></code> the name of the model of the parent in lowercase, so in this case, it will be <code>vehicle_ptr</code>. One might want to provide a field themselves, for example to give this a different name, or to add certain behavior. Therefore a `OneToOneField` accepts an extra [**<code>.parent_link=&hellip;</code>** parameter&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.OneToOneField.parent_link) which is a boolean that can be set to `True` in case the `OneToOneField` acts as a link to that parent.

The `OneToOneField` often gives the wrong impression that if a model `Profile` has a `OneToOneField` to a `User` model for example, it somehow would guarantee that a user has *exactly one* `Profile`. That is not the case: a `OneToOneField` guarantees, if it is not `null=True`, that a `Profile` has exactly *one* related `User` model, and a `User` has *at most one* related `Profile`. It thus will *not* automatically create a `Profile` object in case a `User` object is constructed. Perhaps a more appropriate name might have been an `OptionalToOneField`.


# Summary

|    | `ForeignKey` | `OneToOneField`
|:-- |:--  |:--
| relation type | many-to-one | optional-to-one
| uniqueness | not unique (unless specified) | always unique
| related relation | `RelatedManager` | trying to fetch the reverse object
| parameters | | extra <code>parent_link=&hellip;</code>
