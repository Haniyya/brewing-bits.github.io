---
layout: post
title:  "Off the Rails! Part 1."
date:   2017-09-06 05:16:01 -0100
categories: blog
tags: ['ruby', 'rails', 'grape', 'sequel', 'programming']
published: true
comments: true
excerpted: |
  Although I still like rails, I always enjoyed to be free from the opinions of
  this opinionated framework...

# Does not change and does not remove 'script' variables
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

## Intro

After about 4-5 years of working with [Ruby on
Rails][ruby_on_rails]{:target="_blank"}, I actually still like it. I think the
ecosystem is great, the overall design is well suited to its requirements and I
think the team has a good idea of where the project should be headed
(ActionCable and Api-Mode of Rails 5 are showing that the project is not trying
to compete with the myriads of javascript frameworks out there ).

But every once in a while I regret that I have become so stuck in my ways that I
could not write a simple ruby web app, without some framework giving me
guidance. So I thought, why not try something new and write a JSON-Api,
completely without rails.

## Requirements

For now we don't have a lot of requirements. We'll be building everyones
favorite: A digital library of books. So what we need for now is:

1. Persistence
1. Routing
1. Params handling
1. JSON rendering
1. Some business logic in the form of models

Some things I'll save for later posts:

1. Authentication
1. Authorization
1. Some kind of gui
1. tests

## What will be used

It could be interesting to restrict yourself to nothing but the `STDlib`, but I
don't think this would be practical. So instead I will shamelessly exploit this
chance to try out a few gems that have caught my eye for a while now:

1. [Grape][grape] is a JSON-API framework for ruby. It is similar to rails in
   that it is pretty opinionated, but it does not dictate a rigid structure and
   (in this example), will only be responsible for routing and handling params.
1. [Sequel][sequel] is an ORM (so similar to ActiveRecord if you are comming from
   rails), that will make it easier for us handle persistence.
1. [Rake][rake] for handling development tasks.

This list might very well be expanded in the future, but for now it should
fulfill our humble requirements.

## Come along for the ride!

If you want to follow along, I'll push all the code to [Brewing Bits
github][brewing_github], where you can follow commit by commit.


{% endpost #9D9D9D %}

[ruby_on_rails]: http://rubyonrails.org/
[grape]: https://github.com/ruby-grape/grape
[sequel]: http://sequel.jeremyevans.net/
[rake]: https://github.com/ruby/rake
[brewing_github]: https://github.com/BrewingBits
