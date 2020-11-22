% Giving <code>related_name=&hellip;</code> the same name as the relation

Often one sees modeling with:

<pre><code>from django.db import models

class Profile(models.Model):
    pass

class Post(models.Model):
    author = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        <b>related_name='autor'</b>
    )</code></pre>

# Why it is a problem?

There is often some confusion about the
[**<code>related_name=&hellip;</code>** parameter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.ForeignKey.related_name).
This parameters specifies the name of the relation in *reverse*. It is thus the
name of the relation to access the *related* `Post` objects for a given
`Profile` object. Indeed, with the modeling above, we access the `Post` objects
with:

<pre><code># QuerySet of related <i>Post</i> objects
my_profile.<b>author</b>.all()</code></pre>

But here the relation does not hint that it deals with `Post`s, one here would
think we obtain a single `Author`, or perhaps a set of `Author`s, not `Post`s.

# What can be done to resolve the problem?

Give the <code>related_name=&hellip;</code> a proper value. Sometimes adding the
<code>&hellip;_of</code> suffix is sufficient, like `.author_of`, but still that
is not self-explaining, since a `Profile` can be an author of `Post`s, `Image`s,
etc.

Usually it is better to use the plural of the model name, so `posts`, or do not
specify the <code>related_name=&hellip;</code>, and thus use
<code><i>modelname</i>_set</code>. It becomes more tricking if there are two or
more relations to the same model, because then the default
<code>related_name=&hellip;</code> can not be used because it would collide.

Nevertheless, one should look how the source model relates to the target model,
here these are the authored `Post`s, so we can rewrite this to:

<pre><code>from django.db import models

class Profile(models.Model):
    pass

class Post(models.Model):
    author = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        <b>related_name='authored_posts'</b>
    )</code></pre>

Then we thus query with:

<pre><code># QuerySet of related <i>Post</i> objects
my_profile.<b>authored_posts</b>.all()</code></pre>
