% Modifying slugs and primary keys of model objects
---
type: antipattern
severity: 1
tags: [URL, slug, primary key]
layers: [models, views]
related_packages: []
---

Often if we define a model object, we will access a page
related to that object by making a HTTP request that contains
the primary key, the slug, or even both.

A problem often arises if objects are removed or update. People
often want to avoid "gaps" between primary keys, and thus update
the primary keys that are greater than the one that is removed.

Furthermore if the object itself changes, often developers want
to update the slug accordingly. So if for example a `Blog` model
contains a title, and the slug is derived from that title, then
people want to update the slug accordingly.

# Why is it a problem?

An URI is a *Uniform Resource Identifier*, this thus means that
with such a URI, we can find the data about the object we are looking
for.

Often people will bookmark a page in the browser, send a URI
in an email to a colleague, and search engines might still point
to a page that no longer exists.

In 1998, *Tim Berners-Lee* wrote a document named [*Cool URIs don't change* [w3.org]](https://www.w3.org/Provider/Style/URI.html).
In this document, *Berners-Lee* explains that changing URI's is not a good idea,
and further discusses typical excuses to change an URI.

# What can be done to resolve the problem?

Once the slug and the primary key are set, one usually should not alter these.
If the slug depends on the title, you thus set the slug based on the first
value of the title.

Making no changes to the slug and/or primary key, is however not enough, since
the `urls.py` will determine the URL as well.

If you really need to make a change to the slug and/or primary key, then you should
implement (permanent) redirects ([HTTP 301 [wiki]](https://en.wikipedia.org/wiki/HTTP_301))
from the old URL to the new URL. This thus likely means that you need to make a model
that translates "old" slugs to new slugs. Since slugs should be unique it also
means that you should check if the slug for a new model object is already an old slug.
