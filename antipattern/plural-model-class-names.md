% Plural model class names
---
severity: 1
type: antipattern
typefa: "fas fa-ban"
tags: [nomenclature, name-suffix]
layers: [models]
solinks: []
---

Often people write model classes with a plural name. For example:

```python
from django.db import models

class Cars(models.Model):
    name = models.CharField(max_length=128)
    brand = models.ForeignKey(Brand, on_delete=models.CASCADE)
```

# Why is it a problem?

Django defines some meta data based on the name of the class. For example the
[**`verbose_name`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/options/#django.db.models.Options.verbose_name)
and the [**`verbose_name_plural`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/options/#django.db.models.Options.verbose_name_plural)
are automatically defined if you do not specify these. That thus means that if we inspect
the `verbose_name_plural`, we see:

```pycon
>>> Cars._meta.verbose_name_plural
'carss'
```

Django uses this name for example in the admin page. Some Django packages also
use the `.verbose_name` and `.verbose_name_plural` information to show dialogs
in forms, templates, etc. This will result in grammatically incorrect phrases,
and incorrect plural nouns.

It also makes queries look grammatically incorrect English, for example,
one queries with:

```python
Cars.objects.all()
```

Which can be translated as:

> All the *cars objects*.

The *objects* are already plural, so it makes no sense to make *cars* plural as
well.

For related models, this results in ugly looking names as well, for example one
queries with:

```python
ford.cars_set.all()
```

which again is less elegant compared to `car_set`.

# What can be done to resolve the problem?

You give the class of the model a singular name, so `Car` instead of `Cars`:

<pre class="python"><code>from django.db import models

class <b>Car</b>(models.Model):
    name = models.CharField(max_length=128)
    brand = models.ForeignKey(Brand, on_delete=models.CASCADE)</code></pre>

An alternative could be to specify both the `verbose_name` and the
`verbose_name_plural`, but even then it is likely that there is some Django
tooling, or Django packages that make use of the name of the model, and thus
somehow, it still does not look correct.

## Extra tips

Sometimes people name the model after the table name in a database that already
exists. You can make use of the [**`db_table`** option&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/3.0/ref/models/options/#django.db.models.Options.db_table)
to specify the name of database table, and thus still give your model class a
singular name.
