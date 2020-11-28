% Checking ownership through the `UserPassesTestMixin`

In a view we often want to restrict access to edit an object, for example only
the `author`s of the blog are allowed to edit their `Post`s.

One often checks this with a `UserPassesTestMixin`, which looks like:

<pre><code>from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class BlogEditView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model = Blog
    # &hellip;

    def test_func(self):
        return <b>self.get_object().author = self.request.user</b></code></pre>

# Why it is a problem?

It is not very efficient, because now the `self.get_object()` call will be done
*twice*. Indeed, once for the `test_func`, and one in the
<code>.get(&hellip;)</code> or <code>.post(&hellip;)</code> method, which also
will fetch the object. This even gets worse because the `.author` call will make
an extra query, since it is a `ForeignKey` (or `OneToOneField`), and thus will
lazily load an extra object. If `get_object` is implemented as a simple database
fetch, this thus means we make *two* unnecessary queries.

We can optimize this by dropping a query by using `.author_id` instead of
`.author`:

<pre><code>from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class BlogEditView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model = Blog
    # &hellip;

    def test_func(self):
        return <b>self.get_object().author_id = self.request.user.pk</b></code></pre>

but now we still call `.get_object()` multiple times. This might even generate
problems if we use extra mixins for example that need to performed *before*
using `self.get_object()`.

# What can be done to resolve the problem?

We can filter the `QuerySet` to only retrieve objects where the user is the
author:

<pre><code>from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class BlogEditView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model = Blog
    # &hellip;

    def get_queryset(self, *args, **kwargs):
        return super().get_queryset(*args, **kwargs).filter(
            <b>author=self.request.user</b>
        )</code></pre>

Here we leave filtering to the database side. This might make the query slightly
more expensive, but often a good way to measure performance is the *number* of
queries, and not the queries itself.

Using the `UserPassesTestMixin`, by default it will return a *HTTP 403 Permission denied* response.
This gives a hint that there *is* an object there. If we perform filtering, then
a user that aims to edit the post of another user will see a *HTTP 404 Not Found*, which indicates
that, for that user, this page, and therefore the `Blog` object does not exists.
