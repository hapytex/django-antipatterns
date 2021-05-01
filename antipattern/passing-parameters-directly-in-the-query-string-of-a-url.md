% Passing parameters directly in the query string of a URL
---
type: antipattern
severity: 3
tags: [querystring, querydict, percent encoding]
layers: templates
related_packages: []
---

In many templates variables are passed to the [*query string* [wiki]](https://en.wikipedia.org/wiki/Query_string)
in a URL, for example:

<pre class="html"><code>&lt;a href=&quot;?search={{ <b>search</b> }}&amp;page={{ result.next_page_number }}&quot;&gt;&lt;/a&gt;</code></pre>

# Why is it a problem?

The `search` variable in this case might contain special characters, for example one could search for a string with a question
mark (`?`) and/or ampersand (`&`). If we work then with`foo&bar=qux` as value for `{{ search }}`. If we directly
print this in the URL, then the URL now looks like `?search=foo&amp;bar=qux&page=2`. This is definitely not what is intended, and
Django will parse this as:

```pycon
>>> QueryDict('search=foo&amp;bar=qux&page=2')
<QueryDict: {'search': ['foo'], 'amp': [''], 'bar': ['qux'], 'page': ['2']}>
```

This thus means that we no longer look for `foo&bar`, but for `foo`, and it furthermore creates an extra number of items.

If `search` contains a hash character (`#`), then this acts as the separator between the *query string* and the *fragment* of
the URL. If we for example search for `foo#bar`, then we will retrieve `?query=foo#bar&page=2`, but the part after the hash `#`
will be considered the separator of the querystring with the fragment. For example:

```pycon
>>> urlparse('?search=foo#bar=qux&amp;page=2')
ParseResult(scheme='', netloc='', path='', params='', query='search=foo', fragment='bar=qux&amp;page=2')
```

so `request.GET` will only have one item: with as key `search` and as value `foo`, the rest will not
be interpreted by the server.

# What can be done to resolve the problem?

One can make use of the [**`|urlencode`** template filter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/templates/builtins/#urlencode)
that will percentage encode the values. This means that for `foo&bar=qux`, we get `?query=foo%26bar%3Dqux&page=2`, and for `foo#bar`
we get `?query=foo%23bar&page=2`. These are then converted to:

```pycon
>>> QueryDict('query=foo%26bar%3Dqux&page=2')
<QueryDict: {'query': ['foo&bar=qux'], 'page': ['2']}>
>>> QueryDict('query=foo%23bar')
<QueryDict: {'query': ['foo#bar']}>
```

Django will thus interpret the boundary tokens between the items of the querystring, and the querystring with the fragment correctly
and automatically percentage *decode* the items.

We thus should render this as:

<pre class="html"><code>&lt;a href=&quot;?search={{ search<b>|urlencode</b> }}&amp;page={{ result.next_page_number }}&quot;&gt;&lt;/a&gt;</code></pre>
