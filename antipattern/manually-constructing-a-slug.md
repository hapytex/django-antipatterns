% Manually constructing a slug
---
type: antipattern
typefa: "fas fa-ban"
severity: 3
tags: [slug, url, uri, url-path]
layers: [views, models]
related_packages: [djang-autoslug]
---

Sometimes, people construct slugs manually, for example in a view with:

```python3
model_object.slug = model_object.title.replace(' ', '-')
```

There are several variants of this approach, but often these replace space(s)
with a hyphen.

# Why is it a problem?

Often such algorithms to create a slug are *not* sufficient. Indeed, for example if the
title looks like `'foo costs $0.20'`, then the slug will be `'foo-costs-$0.20'`, but both
`$` and `.` are characters that will not be accepted the <code>&lt;slug:&hellip;&gt;</code>
path converter. While we can of course implement a method that will filter out these characters
it is hard to filter out all characters that will not match the path converter.

Even if the algorithm is smart enough to filter out certain characters, it will often end up with
*strange* slugs. Indeed, if we slugify `'drinking coffee in a café'`, we expect to see
`'drinking-coffee-in-a-cafe'`, but if we remove all characters with a custom algorithm, we end up
with `'drinking-coffee-in-a-caf'`.

Another scenario that is common is that a string might contain leading and trailing spaces, tabs, new lines, etc.
In that case a simple slugify algorithm will replace this with a hyphen, and thus results in a slug
with a leading or trailing hyphen, which looks strange as well. Indeed, if we would slugify `'  to be or not to be'`
with the simple slugify algorithm above, we obtain `'--to-be-or-not-to-be'`.

# What can be done to resolve the problem?

Django has a [**<code>slugify(&hellip;)</code>** function [Django-doc]](https://docs.djangoproject.com/en/dev/ref/utils/#django.utils.text.slugify)
which aims to do a *best effort* in converting a string to a slug. It will remove diacritics, convert
the text to lower case, remove all non-ASCII characters, and eventually replace any sequence of white space
or hyphens with a single hyphen. If we run the titles through the <code>slugify(&hellip;)</code> function, we obtain the
following slugs:

```pycon
>>> from django.utils.text import slugify
>>> slugify('foo-costs-$0.20')
'foo-costs-020'
>>> slugify('drinking-coffee-in-a-café')
'drinking-coffee-in-a-cafe'
>>> slugify('  to be or not to be')
'to-be-or-not-to-be'
```

This thus means that this function will aim to create nice and valid slugs for the situations discussed above.
Usually it is better to work with utility functions that often cover "edge- and corner-cases" that indeed are not
very common, but eventually if the number of blog posts will grow, some posts will have titles that can have invalid
or ugly slug counterparts. Therefore it is in general better to work with a library that often deals with
such cases in a better way.

# Extra tips

Instead of creating a slug in a view, one can work with [**`dango-autoslug`** [readthedocs.io]](https://django-autoslug.readthedocs.io/en/latest/)
and use an [**`AutoSlugField`** [readthedocs.io]](https://django-autoslug.readthedocs.io/en/latest/fields.html#autoslug.fields.AutoSlugField)
to automatically populate a slug field based on another field. This makes the model more *declarative*, and this field
has extra logic to preserve *uniqueness*.
