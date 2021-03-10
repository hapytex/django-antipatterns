% Using <code>len(&hellip;)</code> on a `QuerySet` with no further use
---
severity: 3
type: antipattern
---

People sometimes calculate the number of records by using <code>len(&hellip;)</code>.
For example, if we have a model where comments relate to a post, we can obtain
the number of comments with:

<pre class="python"><code>number_of_comments = <b>len(</b>Comment.objects.filter(post_id=<i>id_of_post</i>)<b>)</b></code></pre>

# Why is it a problem?

Because it is inefficient. It means that Django will *evaluate* the `QuerySet`
and thus load all records into memory. When this is done, it will determine the
number of records. But this thus means that if there are ten comments, we first
will retrieve ten records, deserialize these, and then look at the length of the
list. This means the database will send a lot of data to the Django/Python layer.

If we do *not* iterate over the *same* queryset later on, then all that data has
been retrieved without any use. Indeed, the database itself can determine the
number of records. This will not only minimize the bandwidth, but a database
often will determine the number of records more efficiently through indexing
mechanisms than counting the individual records.

# What can be done to resolve the problem?

A `QuerySet` has a [**`.count()`** method [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#count).
This will make a <code>COUNT(\*) FROM &hellip;</code> query such that
the database will determine the number of records. We thus can transform query
at the top to:

<pre class="python"><code>number_of_comments = Comment.objects.filter(post_id=<i>id_of_post</i>)<b>.count()</b></code></pre>

This is always more efficient, *unless* we later *iterate* over the `QuerySet`.
Indeed, if we would determine the number of comments and then iterate over it,
for example to print the comments, using <code>len(&hellip;)</code> is more
efficient, because then we retrieve and count the number of records with the
same query:

<pre class="python"><code># we here iterate over the <i>same</i> queryset, so this is more
# efficient.

qs = Comment.objects.filter(post_id=<i>id_of_post</i>)

number_of_comments = len(qs)
for comment in qs:
  print(comment)</code></pre>
