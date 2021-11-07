% A SET(…) delete handler with the object as parameter
---
type: pattern
typefa: "fas fa-shapes"
tags: [deletion handler]
layers: [models]
related_packages: []
solinks: [https://stackoverflow.com/q/69207710/67579]
---

Django models offer to specify a piece of logic that will
run for objects that refer to an object through a `ForeignKey` or `OneToOnField`
if that object these refer to is removed.

Often handlers like [**`CASCADE`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.CASCADE) or
[**<code>SET(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#django.db.models.SET). While
<code>SET(&hellip;)</code> can be given a callable, but it takes *no* parameters.

Often, it is useful to be given the instance where the modification should take place, such that a method
based on the data of that instance, can provide a new value for the `ForeignKey` or `OneToOneField`. With this
pattern, we make it also possible to perform a cascaded delete based on that instance.

# What problems are solved with this?

Consider the following model:

<pre class="python"><code>from django.conf import settings
from django.db import models
from <i>app_name</i>.deletion import SET_WITH

def new_organizer(meeting):
    # &hellip;
    pass

class Meeting(models.Model):
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=SET_WITH(new_organizer),
        related_name='organized_meetings'
    )
    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL
    )</code></pre>

Here we have a model `Meeting` that is linked to multiple `participants`, and one `organizer`. If the `User` object that
is the `organizer` is removed, another person that is a participant is upgraded as `organizer`. In case there are no participants
anymore, the meeting object should be removed.

For this we will implement the `SET_WITH` deletion handler. This will make a call to the `new_organizer` function, which will
return a new value for the `organizer`, or can also signal that the `Meeting` object should be removed as well, so with a *cascade* removal.

# What does this pattern look like?

We can take a look at the [implementation of the `SET` handler [GitHub]](https://github.com/django/django/blob/stable/4.0.x/django/db/models/deletion.py#L46-L54):

<blockquote><pre class="python"><code>def SET(value):
    if callable(value):
        def set_on_delete(collector, field, sub_objs, using):
            collector.add_field_update(field, value(), sub_objs)
    else:
        def set_on_delete(collector, field, sub_objs, using):
            collector.add_field_update(field, value, sub_objs)
    set_on_delete.deconstruct = lambda: ('django.db.models.SET', (value,), {})
    return set_on_delete</code></pre></blockquote>

This function needs to return a function that will then later be called with a `collector`, `field`, `sub_objs` and `using`.
The collector is an object that keeps track on what fields to update to what value, and what items to remove. The field
is a reference to the field object that is here triggered. This can be useful, for example to determine the `.default` attribute.
The `sub_objs` is a collection of objects that needs to be updated. These are all model objects with as model the model
where the deletion handler is set. Finally `using` specifies what database connection should be used to update objects.

Here `SET` will first check if `value` is a callable of not. If it is not a callable, it will for all the `sub_objs` specify in
the collector that these should be updated with `value`. If it is a callable, these will all be updated with `value()`.

What we need to change is the fact that not all these `sub_objs` are updated to `value`, or `value()`, but that we *call* the function
with each object in the `sub_objs`, and for each of these items add the result in the collector.

It is possible that we might want to remove a (subset) of the `sub_objs`. We can do this with by constructing an object `DO_CASCADE`.
In case the function returns *that* object, then it will be added to the list of items that we will then collect to perform a cascade.

<pre class="python"><code># <i>app_name</i>/deletion.py

from django.db.models.deletion import CASCADE

DO_CASCADE = object()

def SET_WITH(func):
    def set_on_delete(collector, field, sub_objs, using):
        cascades = []
        for obj in sub_objs:
            <b>result = func(obj)</b>
            if result is DO_CASCADE:
                cascades.append(obj)
            else:
                collector.add_field_update(field, result, [obj])
        if cascades:
            CASCADE(collector, field, cascades, using)
    set_on_delete.deconstruct = lambda: ('<i>app_name</i>.SET_WITH', (func,), {})
    return set_on_delete</code></pre>

Now that we have implemented the <code>SET_WITH(&hellip;)</code> handler, we can use this for the implementation of our <code>new_organizer(&hellip;)</code> method.
This function takes the `Meeting` object, and will look for the user object that is not the user that is the `organizer`, and we check if there
is at least such element. If not, we return the `DO_CASCADE` method to perform a cascaded removal:

<pre class="python3"><code>from <i>app_name</i>.deletion import DO_CASCADE

def new_organizer(meeting):
    item = meeting.members.exclude(pk=meeting.organizer_id).first()
    if item is None:
        return DO_CASCADE
    return item</code></pre>

We thus first access the `.members` and will exclude the `organizer_id` to prevent assigning the organizer
that is not *yet* removed from the `.members`. We access the `.first()` item. If it is `None`, that means
that there are no `members` left, so then we return `DO_CASCADE` to ensure that the `Meeting` object will be removed.
In case it returns a user object, we use that as the new value for the `.organizer`.
