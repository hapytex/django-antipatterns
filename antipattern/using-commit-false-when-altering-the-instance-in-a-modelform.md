% Using `commit=False` when altering the instance in a `ModelForm`
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [form, no-update, many-to-many relation]
layers: [forms, views]
---

Often one sees a pattern where one aims to update an instance wrapped in a
`ModelForm` before creating a record in the database. A programmer often writes:

<pre class="python"><code>form = MyFormClass(request.POST, request.FILES)
if form.is_valid():
    object = form.save(<b>commit=False</b>)
    object.some_attribute = some_value
    object.save()</code></pre>

# Why is it a problem?

Because `commit=False` does not only result in *not* creating a record at the
database. It also has for example impact on many-to-many fields in the form.

When you thus specify `commit=False`, the `ManyToManyField`s of the model that
are also present in the form, are not stored in the database either, since at
that moment, no primary key for the object exists yet.

One can of course implement the logic themselves, but the idea of a `ModelForm`
is to remove as much boilerplate code as possible.


# What can be done to resolve the problem?

You alter the instance wrapped in the form *before* saving the form, so:

<pre class="python"><code>form = MyFormClass(request.POST, request.FILES)
if form.is_valid():
    form<b>.instance.some_attribute = some_value</b>
    form.save()</code></pre>

That way the form can still handle other tasks it needs to carry out in the
`save` method, and furthermore it is a more "*clean*" implementation.
