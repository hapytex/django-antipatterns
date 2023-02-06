% A certain field does not appear in the migrations and in the database table
---
type: troubleshooting
typefa: "fas fa-bug"
tags: [field, column, database]
layers: [models]
solinks: []
---

There are several questions on *StackOverflow* regarding a field that is defined in a model, but does not appear in the database
after making migrations and migrating.

# What are the *symptoms*?

If we inspect the migration file that was constructed by the [**`makemigrations`** command&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/django-admin/#django-admin-makemigrations),
we see that only a subset of the fields (or none at all) are mentioned, and some fields that have been defined in the model are thus missing.

# What is a *possible* fix?

Usually this is caused because we did not define that field correctly in the model. There are typically three variants to that problem.

## Variant 1: Trailing comma

Some people tend to end the line of a field with a comma, for example:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    #                     a trailing comma &downarrow;
    name = models.CharField(max_length=128)<b>,</b></code></pre>

This will wrap the `CharField` in a singleton tuple (a tuple with one element).
Django will look for items in the class that are subclasses of the [**`Field`** class&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/3.2/ref/models/fields/#field-options). While the tuple wraps a `CharField` that is a subclass of `Field`,
a singleton tuple that contains such element is *not*, so Django will not recognize it.

In that case you thus drop the trailing comma, and work with:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    #                    <i>no</i> trailing comma &downarrow;
    name = models.CharField(max_length=128)</code></pre>


## Variant 2: Using a colon between the name of the field and the field

Often people write classes like one writes a dictionary literal: with a colon (`:`) between the key
and the value. This thus can look like:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    #    &downarrow; a colon
    name <b>:</b> models.CharField(max_length=128)</code></pre>

This is *not* a way to define a class attribute. The colon is used for annotations. Indeed, if we
inspect `MyModel`, we see:

```pycon
>>> MyModel.name
Traceback (most recent call last):
  File "<console>", line 1, in <module>
AttributeError: type object 'MyModel' has no attribute 'name'
```

Colons are here used to create *type annotations*. Indeed, if we inspect the `__annotations__` attribute
of `MyModel`, we see:

```
>>> MyModel.__annotations__
{'name': <django.db.models.fields.CharField>}
```

We here thus made an annotation to specify that `name` will have a certain type, but we never define `name`
at the class level.

We thus should replace the colon with an equals sign (`=`):

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    #    &downarrow; <i>equals sign</i> instead of a colon
    name <b>=</b> models.CharField(max_length=128)</code></pre>

## Variant 3: mixing form fields and model fields

Another common variant is mixing *model* fields with *form* fields. It is easy to make such mistake,
since a lot of form fields have the same class name as their model field. Especially if one uses an
IDE, and then for example writes `CharField`, it is possible that the IDE will propose to import
the wrong module. This thus could look like:

<pre class="python"><code>from django.db import models
from django.forms import <b>CharField</b>

class MyModel(models.Model):
    #         &downarrow; CharField from the django.forms module
    name = <b>CharField(</b>max_length=128<b>)</b></code></pre>

Since this `CharField` does not inherit from the `Field` of the `django.db.models` module, again
Django will not see this as a field that should be included in the migration.

In Django *model fields* focus in *storing* data in the database, whereas *form fields* help
to process data when a form is submitted. It thus makes no sense that model fields appear in forms,
or that form fields appear in models.

Therefore it might be better to import the `django.db.models` module, and always use `models.CharField`
in that case it gives a visual hint that it is using the correct field:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    #         &downarrow; import from the models module.
    name = <b>models.</b>CharField(max_length=128)</code></pre>
