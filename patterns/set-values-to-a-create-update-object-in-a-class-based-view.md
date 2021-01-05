% Set values to a create/update object in a class-based view
---
type: pattern
---
Often not all fields specified in a model are specified through a form.
These for example originate for example through the path, or we make use of the
logged in user. Take for example the following model:

```python
from django.conf import settings
from django.db import models

class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    comment = models.CharField(max_length=1024)
    posted_at = models.DateTimeField(auto_now_add=True)
```

The form will normally only take the `comment` as field, not the `post` and
`author`. We can for example specify the primary key of the post in the path,
and the autor is normally the logged in user. The form thus looks like:

```python3
from django import forms

class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ['comment']
```

and the path to the view will have a primary key that specifies to what post we
comment:

<pre class="python"><code>from django.urls import path
from <i>app_name</i>.views import CreateCommentView

urlpatterns = [
    path('post/&lt;int:pk&gt;/comment', CreateCommentView.as_view()),
]</code></pre>

# What problems are solved with this?

A class-based view is powerful, but it is often not entirely clear where to
add certain logic to alter the codeflow slightly. Often people will alter the
entire <code>.post(&hellip;)</code> method. This destroys most of the
boilerplate code in the view. This does not only mean the user needs to define
a long view, but it is also likely that the user will not think about everything
in advance. For example people often forget to pass `request.FILES` to the form.

It also makes it easy to wrap the logic to "*inject*" data into the form
instance through a *mixin*: this makes the logic to inject data more *reusable*.

# What does this pattern look like?

We override the [**<code>.form_valid(&hellip;)</code>** method [Django-doc]](https://docs.djangoproject.com/en/dev/ref/class-based-views/mixins-editing/#django.views.generic.edit.FormMixin.form_valid)
of the view with the `FormMixin`, and there we can alter the `.instance` wrapped
in the form, for example:

<pre class="python"><code>from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic.edit import CreateView
from <i>app_name</i>.forms import CommentForm

class CommentCreateView(LoginRequiredMixin, CreateView):
    form_class = CommentForm

    def <b>form_valid</b>(self, form):
        form<b>.instance.author = self.request.user</b>
        form<b>.instance.post_id = self.kwargs['pk']</b>
        return super().form_valid(form)</code></pre>

If we need the logic in multiple views, we can easily encapsulate this in a
mixin, for example:

<pre class="python"><code>from django.contrib.auth.mixins import LoginRequiredMixin

class SetAuthorMixin(LoginRequiredMixin):

    def form_valid(self, form):
        form<b>.instance.author = self.request.user</b>
        return super().form_valid(form)</code></pre>

then the mixin can be used, for example in both views that create a `Post` and a
`Comment`:

<pre class="python"><code>from django.views.generic.edit import CreateView
from <i>app_name</i>.forms import CommentForm, PostForm

class CommentCreateView(SetAuthorMixin, CreateView):
    form_class = PostForm


class CommentCreateView(SetAuthorMixin, CreateView):
    form_class = CommentForm

    def form_valid(self, form):
        form<b>.instance.post_id = self.kwargs['pk']</b>
        return super().form_valid(form)</code></pre>


This not only makes it easier to reuse logic. It also makes it easier to fix a
mistake: if the mistake is only made in one mixin, it is easy to fix the problem
for all views with that logic, instead of searching for all views that
implemented (variants) of that logic.

# Extra tips

For `DateTimeField`s and `DateField`s we can make use of the
[**<code>auto_now_add=&hellip;</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.DateField.auto_now_add) or
[**<code>auto_now=&hellip;</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.DateField.auto_now) can be used to
automatically specify the current timestamp to specify when to *create* or *update* the object.
