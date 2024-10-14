% querying in the opposite direction
---
type: pattern
typefa: "fas fa-shapes"
tags: [orm, query, lookup]
layers: [orm, views, models]
related_packages: []
solinks: ["https://stackoverflow.com/questions/78132711/i-need-a-django-filter-query-that-takes-a-string-as-argument-and-it-gets-matched"]
---

# What problems are solved with this?


Django's ORM is quite expressive, and lookups can be used to filter in a specific way, for example:

```python
MyModel.objects.filter(title__regex='^[0-9]+$')
```

will search for `MyModel` objects where the title satisfies a certain regex. Sometimes we however might want to do the opposite: a model might contain a lot of regex patterns, we are given a string to satisfy these, and then want to find the `MyModel`s that have a pattern that contains this regex.

At the moment of writing there is no reverse lookup: we can not perform a `MyModel.objects.filter(pattern__reverse_regex='test_string')` where `pattern` is a field in `MyModel` that contains the regex, and we want to look for `MyModel`s where the `pattern` accepts in this case `'test_string'` as a string for this pattern.

# What does this pattern look like?

A simple, but a bit "*ugly*" way to solve this is by using [**<code>.alias(&hellip;)</code>**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/models/querysets/#alias) to "inject" the value as a field in the queryset and then thus query with that "field", we can then use an [**`F`** expression&nbsp;<sup>\[Django-doc\]](https://docs.djangoproject.com/en/stable/ref/models/expressions/#django.db.models.F) to refer to the `pattern` field. This thus then looks like:

```python
from django.db.models import F, Value

MyModel.objects.alias(val=Value('test_string')).filter(val__regex=F('pattern'))
```

Since we use <code>.alias(&hellip;)</code> the value will not appear in the `SELECT` clause, which is a good thing, but it looks a bit "*hacky*".

But probably a more robust, and clearer way to show what we are doing, is building a query object like Django does behind the curtains when we perform lookups. Indeed, if we write `pattern__regex`, it makes a lookup for a field named `pattern`, and inspects what type of field it is. For a `CharField` a different set of lookups will be "registered". If we then write `__regex`, it will start looking for a lookup registered at this field with the name `regex`. These lookups typically reside in the `django.db.models.lookups` module. For this specific case, this is the `Regex` class. We thus can construct such query with:

```python
from django.db.models import F, Value
from django.db.models.lookups import Regex

MyModel.objects.filter(Regex(Value('test_string'), F('pattern')))
```

This is equivalent to the query above, but makes it clear we want to filter based on a regex, where `Value('test_string')` is the string we want to test, and the field `pattern` (`F('pattern')`) is the regex we will use to test the string.
