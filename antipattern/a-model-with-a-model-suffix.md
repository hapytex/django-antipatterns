% A model with a <code>&hellip;Model</code> suffix
---
severity: 1
type: antipattern
typefa: "fas fa-ban"
tags: [pep-8, style-guidelines]
layers: [models]
solinks: []
---

Often people use a <code>&hellip;Model</code> suffix for their model, for
example:

<pre class="python"><code>from django.db import models

class <b>CarModel</b>(models.Model):
    # &hellip;
    pass</code></pre>

# Why is it a problem?

Because objects from a model are not *models*, these are *cars*, not *car
models*. Django will also construct verbose named based on the name of the
class. Indeed, unless you specify
[**`verbose_name`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/options/#verbose-name) and
[**`verbose_name_plural`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/options/#verbose-name-plural)
yourself, Django will "*unsnake*" the name and thus give a verbose name like:

```pycon
>>> CarModel._meta.verbose_name
'car model'
>>> CarModel._meta.verbose_name_plural
'car models'
```

This thus means that Django will ask questions in the model admin like:

> Are you sure you want to remove this car model?

# What can be done to resolve the problem?

Remove the <code>&hellip;Model</code> suffix. Django models are not supposed to
have a <code>&hellip;Model</code> suffix, so:

<pre class="python"><code>from django.db import models

class <b>Car</b>(models.Model):
    # &hellip;
    pass</code></pre>
