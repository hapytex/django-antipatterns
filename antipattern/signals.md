% Signals
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [signals, updates, modeling]
layers: [signals]
solinks: []
---

Django has a sophisticated system to trigger certain logic when
you save, delete, change many-to-many relations, etc. Very often
people make use of such signals and for some edge-cases these are
indeed the only effective solution, but there are only a few cases
where using signals is appropriate.

# Why is it a problem?

Signals have a variety of problems and unforeseen consequences. In the below sections, we list a few.

## Signals can be circumvented

One of the main problems with signals is that signals do *not* always run.
Indeed the `pre_save` and `post_save` signals will *not* run when we save
or update objects in bulk. For example if we create multiple `Post`s with:

<pre class="python"><code>Post.objects.<b>bulk_create(</b>[
    Post(title='foo'),
    Post(title='bar'),
    Post(title='qux')
]<b>)</b></code></pre>

then the signals do not run. The same happens when you update posts, for example
with:

<pre class="python"><code>Post.objects.all().<b>update(</b>views=0<b>)</b></code></pre>

Often people assume that signals *will* run in that case, and for example
perform calculations with the signals: they recalculate a certain field, based
on the updated values. Since one can update a field *without* triggering the
the corresponding signals, then this results in an inconsistent value. Signals
thus give a *false sense of security* that the handler will indeed update the
object accordingly.

## Signals are request unaware

Every now and then people try to implement a signal that needs a request object
to perform a certain piece of logic. For example one might want to send an email
each time a certain model is created to the person that made the HTTP request.

Django's signal processing however does not capture the request. This makes sense
since these signals get fired by models that are created, updated, removed, etc. and
models are request unaware as well.

The fact that these are request unaware makes it harder to implement certain behavior.
For example a signal that updates the `owner` field of a model object with the currently
logged in user. Strictly speaking it *is* possible to implement this, for example
by inspecting the call stack. If the signal is triggered by a view, eventually
one will find a call to that view, and thus one can obtain the `request` object. Another
way to do this would be to implement middleware that keeps track of the user that makes
the request, and then uses that, but that will introduce a *global state* antipattern.

This thus means that while technically there are some ways to make signals request-aware
these solutions are often *ugly* and furthermore can fail if a management command
triggers the change.

## Signals can raise exceptions and break the code flow

If the signals run, for example when we call `.save()` on a model object, then
the triggers *will* run. Contrary to popular belief, signals do *not* run asynchronous,
but in a synchronous manner: there is a list of functions and these will all run.
A second problem is that these signals might raise an error, and this will thus
result in the function that triggered the views, raising that error.
Developers often do not take this into account.

If such error is raised, then eventually the `.save()` call will raise an error. Even if
the developer takes this into account, it is hard to anticipate on the consequences: if there
are multiple handlers for the same signal, then some of the handlers can have made changes
whereas others might not have been invoked. It thus makes it more complicated to repair
the object, since the handlers might already have changed the object partially.

## Signals can result in infinite recursion

It is also rather easy to get stuck in an infinite loop with signals. If we for example have a model of a
`Profile` with a signal that will remove the `User` if we remove the `Profile`:

<pre class="python"><code>from django.db import models
from django.db.models.signals import pre_delete
from django.dispatch import receiver

class Profile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

# &hellip;

@receiver(pre_delete, sender=Profile)
def delete_profile(sender, instance, using):
    instance.user.delete()</code></pre>

If we now remove a `Profile`, this will get stuck in an infinite loop. Indeed, first we start
removing a `Profile`. This will trigger the signal to run, which will remove the related user object.
But Django will look what to do when removing the user, and it thus will *first* remove the `Profile` again
triggering the signal. It is easy to end up with infinite recursion when defining signals. Especially if we
use signals on two models that are related to each other.

## Signals run before updating many-to-many relations

The `pre_save` and `post_save` signals of an object run immediately before and after an object
is saved to the database. If we have a model with a `ManyToManyField`, then when we create that
object and the signals run, the `ManyToManyField` is *not* yet populated. This is because a `ModelForm`
first needs to create the object, before that object has a primary key and thus can start populating
the many-to-many relation. If we for example have two models `Author` and `Book` with a many-to-many
relation, and we want to use a signal that counts the number of books an `Author` has written, then the
following signal will not work when we create an `Author`, and the form also to specify the books:

<pre class="python"><code>from django.db.models.signals import pre_save
from django.dispatch import receiver

@receiver(pre_save, sender=Author)
def save_author(sender, instance, created, raw, using, update_fields):
    instance.num_books = instance.books.count()</code></pre>

Regardless whether we use a `pre_save` or `post_save` signal, at that moment in time `instance.books.all()`
is an empty queryset.

## Signals make altering objects less predictable

Even if only one handler is attached to the the signal, and that handler can never raise an error,
the handler still is often not an elegant solution. Another developer might not be aware of its existence,
since it has only a "weak" binding to the model, and thus it makes the effect of saving an object less
predictable.

## Signals do not run in data migrations

One can construct a [*data migration*&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/howto/writing-migrations/#how-to-create-database-migrations),
such migration could populate a database table, for example:

```python3
from django.apps import apps as global_apps
from django.db import migrations

def forwards(apps, schema_editor):
    ModelName = apps.get_model('app_name', 'ModelName')
    ModelName.objects.create(
        first_name='foo', last_name='Bar'
    )

class Migration(migrations.Migration):
    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
    dependencies = [
        ('app_name', '1234_other_migration'),
    ]
```

here we thust create a `ModelName` record. We however use a *historical* model: that means the `ModelName` with the fields
defined on the model at the state after applying all dependencies, not *per se* the current `ModelName` model. Regardless,
whether that model is equivalent to current model, it is quite limited. One of the consequences is that signals are *not*
attached to that model, and thus if there is for example a `post_save` signal defined on `ModelName`, than these signals,
nor the historical nor the current ones will run, and hence the anticipated effects of these signals will thus *not* take
place.

## Signals do not run when other programs make changes

Finally other programs can also make changes to the database, and thus will not trigger the signals,
and this eventually could lead to the database being in an inconsistent state. Another program could for
example create a new book for an author, but might not update the field in the `Author` model that keeps
track of the number of books written by that author. It will be quite hard to "translate" all the handlers
in Django to other programs that interact with the same database.

# What can be done to resolve the problem?

Often it is better to avoid using signals. One can implement a lot of logic *without* signals.

## Calculating properties on-demand

The most robust way to count the number of `Book`s of an `Author` is *not* to store the number of books in
a field, but use [**<code>.annotate(&hellip;)</code>**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/querysets/#annotate)
to each time annotate the `Author`s with the number of `Book`s they have written. We thus can make a query
that looks like:

<pre class="python"><code>from django.db.models import <b>Count</b>

Author.objects.annotate(
    <b>num_books=Count('books')</b>
)</code></pre>

Often if the number of `Book`s is not that large, this will still scale quite well. It is more robust: if somehow
another program removed a book, or a view was triggered that somehow circumvented the update logic, it will
still work with the correct amount of books.

Here of course we each time recalculate the number of `Book`s per `Author` when we query. If the number of `Book`s
and `Author`s grows, then this can become a performance bottleneck.

## Encapsulating update logic in the view/form and ModelAdmin

Another option might be to encapsulate the handler logic in a specific function. For example if we want to count the number of
books of an `Author` each time we save/update a `Book`, we can implement the logic:

```python3
def update_book(book):
    author = book.author
    author.num_books = author.books.count()
    author.save()
```

and then we can call this function in the views where we create/update the book. For example:

<pre class="python"><code>def my_view(request):
    if request.method == 'POST':
        form = BookForm(request.POST, request.FILES)
        if form.is_valid():
            book = form.save()
            <b>update_book(</b>book<b>)</b>
            # &hellip;
        # &hellip;
    # &hellip;</code></pre>

we can also construct a mixin that we can use in class-based views and the `ModelAdmin`:

<pre class="python"><code>from django.contrib import admin

class MyModelAdmin(admin.ModelAdmin):
    
    def save_model(self, request, obj, form, change):
        <b>update_book(</b>obj<b>)</b>
        super().save_model(request, obj, form, change)</code></pre>

If the task takes too much time, you can set up a queue where a message is queued
that will then trigger a task to update the data. This is however not something specific
to encapsulate logic into a function: if you work with signals, then these signals can
go in timeout as well, and thus render the server irresponsive.

# Extra tips

Signals can still be a good solution if you want to handle events raised by a *third party* Django application.
In many cases, this is the only effective way to handle certain events. For example the `auth` module provides
[signals when the user logs in, logs out, or fails to log in&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/contrib/auth/#module-django.contrib.auth.signals)
these signals are typically more reliable, since these are not triggered by the ORM. Often for third party applications
signals are an effective way to communicate with these applications.

If you define signals, you should be aware that these will *not* run in data migrations. You will thus have to
write the logic that is otherwise done by the signals in the data migration file as well.
