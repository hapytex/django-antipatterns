% Using regular HTML comments instead of Django template comments
---
author: Alex Deathway
severity: 1
type: antipattern
typefa: "fas fa-ban"
tags: [templates, comments]
layers: [templates]
related_packages: []
solinks: []
---

# Why is it a problem?

Using regular HTML comments (text between `<!--` and `-->`) in templates causes the Django template engine to render these comments in the HTML page
that is produced, usually these comments are intended for developers, and thus can expose certain aspects of the web server. Such comment can
for example look like:

<pre class="django"><code>
&lt;!-- <s>exclude dashboard for 
			  -not authenticated users
			  -users with not enough privilege</s>
--&gt;</code></pre>

# What can be done to resolve the problem?

The Django template engine has enabled comment sections. One can write a single line comment between `{#` and `#}`, for example:

<pre class="django"><code><b>{#</b> your comment here <b>#}</b></code></pre>

or one can make use of the [**<code>{% comment %}&hellip;{% endcomment %}</code>** template tags [Django-doc]](https://docs.djangoproject.com/en/dev/ref/templates/builtins/#comment)
to write comments that span over multiple lines, for example:

<pre class="django"><code><b>{% comment %}</b>
	your 
	multiline 
	comment 
	here
<b>{% endcomment %}</b></code></pre>
