% Use `datetime.now` as <code>default=&hellip;</code> for a `created_on` field
---
severity: 2
---

Often people make use of `datetime.now` as a default value to specify a field
that stores when a record was created, so something like:

<pre class="python"><code>from datetime import datetime
from django.db import models

class Post(models.Model):
    created_on = models.DateTimeField(<b>default=datetime.now</b>)</code></pre>

# Why is it a problem?

A field is by default editable and not optional. This thus means that if you
construct a `ModelForm` with `fields = '__all__'`, then this will incude the
`created_on` in the form. Normally we do not want to include this. While it is
of course possible to create a `DateTimeField` with `blank=True` and
`editable=False`, but if later additional features arise, one needs to specify
more attributes.

Furthermore [**`datetime.now()`** [python-doc]](https://docs.python.org/3/library/datetime.html#datetime.datetime.now)
does not include a timezone. This thus means that the database will store the
timestamp without timezone. If thus later the server works with a different
timezone, it will render different timestamps.

If one makes use of the [**`freezegun`**
[GitHub]](https://github.com/spulec/freezegun), then making use of
`datetime.now` directly will not work. Indeed, if we first define a reference to
`now()`, then freezing the time will not have impact:

```pycon
>>> from datetime import datetime
>>> from freezegun import freeze_time
>>> nw = datetime.now
>>> with freeze_time('1958-3-25'):
...     print(nw())
...     print(datetime.now())
...
2020-12-06 17:05:35.861048
1958-03-25 00:00:00
```

so tests with the freezegun will not work.

# What can be done to resolve the problem?

Django's `DateTimeField` and `DateField` has a
[**<code>auto_now_add=&hellip;</code>** parameter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.DateField.auto_now_add).
By setting this parameter to `True`, you automatically use the current timestamp
when you construct the model object. We thus can construct a `DateTimeField`
with `auto_now_add=True`:

<pre class="python"><code>from django.db import models

class Post(models.Model):
    created_on = models.DateTimeField(<b>auto_now_add=True</b>)</code></pre>

# Extra tips

Django's `DateTimeField` and `DateField` have a
[**<code>auto_now=&hellip;</code>** parameter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.DateField.auto_now)
as well. This is a field that will each time take the current timestamp when you
update the record, so this can be used for an `updated_at` field.
