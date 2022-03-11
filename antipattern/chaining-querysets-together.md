% `Chain`ing querysets together
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [itertools, chain, queryset]
layers: [views, orm]
solinks: []
---

We can chain querysets together with the [**<code>chain(&hellip;)</code>** function&nbsp;<sup>[python-doc]</sup>](https://docs.python.org/3/library/itertools.html#itertools.chain)
of the [**`itertools`** package&nbsp;<sup>[python-doc]</sup>](https://docs.python.org/3/library/itertools.html#itertools.chain). For example if we have two `Post`s, we can chain
the posts with a `publish_date` and then the ones where the `publish_date` is `NULL`:

<pre class="python"><code>from itertools import chain

qs1 = Post.objects.filter(publish_date__isnull=False).order_by('publish_date')
qs2 = Post.objects.filter(publish_date=None)

result = <b>chain(</b>qs1, qs2<b>)</b></code></pre>

# Why is it a problem?

The main problem is that the result is *not* a `QuerySet`, but a `chain` object.
This means that all methods offered by a `QuerySet` can no longer be used.
Indeed, say that we want to filter the `Post`s with:

<pre class="python"><code>result.filter(author=<i>some_author</i>)</code></pre>

then this will raise an error. Often such filtering is *not* done explicitly in
the view, but for example by a `FilterSet` the developer wants to use.

Another problem is that a `chain` can not be enumerated multiple times. Indeed:

```pycon
>>> c = chain([1,4], [2,5])
>>> list(c)
[1, 4, 2, 5]
>>> list(c)
[]
```

This thus means if multiple `for` loops are used, only the first will iterate
over the elements. We can work with <code>list(&hellip;)</code>,
and thus use <code>result = list(chain(qs1, qs2))</code> to prevent this effect.

Another problem is that `result` will eventually perform multiple queries. In
this example there will be *two* queries. If we chain however five querysets
together, it results in (at least) five queries. This thus makes it more
expensive.

# What can be done to resolve the problem?

Group the queries together into a single queryset. If the order is of no
importance, we can make use of the `|` operator:

<pre class="python"><code>result = qs1 <b>|</b> qs2</code></pre>

if the order is of importance, we can make use of [**<code>.union(&hellip;)</code>**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/querysets/#union):

<pre class="python"><code>qs1.<b>union(</b>qs2<b>, all=True)</b></code></pre>

# Extra tips

We can use <code>chain(&hellip;)</code> when we query for example different
models like:

<pre class="python"><code>from itertools import chain

qs1 = Post.objects.all()
qs2 = Author.objects.all()

result = list(chain(qs1, qs2))</code></pre>

But it is seldomly the case that a collection contains elements of a
different type. Especially since very often processing `Post`s will be different
from processing `Author`s.
