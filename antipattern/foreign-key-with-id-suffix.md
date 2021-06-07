% Foreign key with `_id` suffix
---
severity: 1
type: antipattern
typefa: "fas fa-ban"
tags: []
layers: [models]
---

Often people add an `_id` suffix to the `ForeignKey`s or `OneToOneField`s in
their models, for example:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    other_model<b>_id</b> = models.ForeignKey(OtherModel, on_delete=models.CASCADE)</code></pre>

# Why is it a problem?

The main reason why it is a problem is because the `.other_model` itself does
*not* store the id. Indeed, Django makes an implicit *twin*-field with an `_id`
suffix that stores the primary key (or another unique column if you specify
that) to the target model. The `ForeignKey` itself is designed to (lazily) load
the related model.

It furthermore means that the twin-field Django has constructed is now named
`other_model_id_id`, which is also the default name of the column where it
stores the primary key. This name is rather "*ugly*".

# What can be done to resolve the problem?

Renaming the field without the `_id` suffix, so change it to:

<pre class="python"><code>from django.db import models

class MyModel(models.Model):
    <b>other_model</b> = models.ForeignKey(OtherModel, on_delete=models.CASCADE)</code></pre>

You will need to run `makemigrations` to rename the field. The Django
makemigrations tool will likely detect that you renamed the field and ask:

> `Did you rename mymodel.other_model_id to activity.other_model (a ForeignKey)? [y/N]`

A question that should be answered with `y`es.
