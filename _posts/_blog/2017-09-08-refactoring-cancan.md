---
layout: post
title:  "Refactoring CanCan(Can) Abilities"
date:   2017-09-07 09:31:01 +0100
categories: blog
tags: ['ruby', 'rails', 'cancan', 'programming']
published: true
comments: true
excerpted: |
  If you have a somewhat complicated set of authorization-rules in your system,
  your CanCan(Can) Abilities can become quite unwieldy. Here are some tips to
  make them more manageable.

# Does not change and does not remove 'script' variables
script: [post.js]
---

* Do not remove this line (it will not be displayed)
{: toc}

If you have a somewhat complicated set of authorization-rules in your system,
your [CanCan(Can)][cancan] Abilities can become quite unwieldy. Here are some tips to
make them more manageable.

## Use Arrays

There is an antipattern when using `CanCan::Ability`, that iterates over objects
or verbs to define a bunch of rules that could be expressed a lot easier.
Example:

### Bad:
{% highlight ruby tabsize=4 %}
# ability.rb

[:message, :block, :like].each do |verb|
  can verb, UserProfile
end
{% endhighlight %}

This defining 3 rules, where only one is needed.

### Good:
{% highlight ruby tabsize=4 %}
# ability.rb

can [:message, :block, :like], UserProfile

# Or use a literal

can %i(message block like), UserProfile

# You can use this on the objects as well
can :ignore, [UserProfile, Admin]
{% endhighlight %}

## Prefer hashes to blocks

Block arguments to rules are slow and cannot be used in db-queries. If you can
(and you won't always be able to) you should instead use hash-arguments:

### Bad:
{% highlight ruby tabsize=4 %}
# ability.rb

# Assuming you refer to your logged in user with `user`
can :edit, Post do |post|
  post.author == user
end
{% endhighlight %}

### Good:
{% highlight ruby tabsize=4 %}
# ability.rb

can :edit, Post, author: user
{% endhighlight %}

## If you use concerns, use concerns

If you use [Concerns][concerns] you can use that fact to skip tests in your
rules. Since `CanCan` internally uses [`#kind_of?`][kind_of] to test for
applicable rules, you can just as well pass modules as objects of your rules.

### Bad:
{% highlight ruby tabsize=4 %}
# ability.rb

can :message, [User, Admin] do |user|
  user.respond_to?(:received_messages)
end
{% endhighlight %}

### Good:
{% highlight ruby tabsize=4 %}
# ability.rb
# Assuming both User and Admin include a messageable concern to send them
# messages.

can :message, Messageable
{% endhighlight %}

## Use `cannot` for exceptions instead of blocks

If you have exceptions to a rule, or negative conditions, try to use `cannot`!
### Bad:
{% highlight ruby tabsize=4 %}
can :message, User

# You can block everyone but yourself
can :block, User do |user|
  user != current_user
end

{% endhighlight %}

Again, this is slow and not SQL compatible. Instead use something like this:

### Good:
{% highlight ruby tabsize=4 %}
can %i(message block), User
cannot :block, User, user_id: current_user.id
{% endhighlight %}

Remember the rule-precedence of CanCan: Rules you define later will override the
earlier ones.

## Use `#merge` to extract logic from your main ability

If you tried all of the above but somehow still have a file that is way to long,
you can try to split it into multiple small abilities (you could call them
faculties).
### Bad:
{% highlight ruby tabsize=4 %}
# ability.rb

class Ability
  include CanCan::Ability

  def initialize(current_user)
    can :message, User
    can :block, User
    can :edit, Post, author: current_user

    # 300 lines later

    cannot :block, User, user_id: current_user.id
  end
end
{% endhighlight %}

### Good:
{% highlight ruby tabsize=4 %}
class Ability
  include CanCan::Ability

  def initialize(current_user)
    [ContentFaculty, InteractionFaculty].map do |klass|
      merge klass.new(current_user)
     end
  end
end

class ContentFaculty
  include CanCan::Ability

  def initialize(current_user)
    can :edit, Post, author: current_user
  end
end

class InteractionFaculty
  include CanCan::Ability

  def initialize(current_user)
    can %i(message block), User
    cannot :block, User, user_id: current_user.id
  end
end
{% endhighlight %}

This way you can keep the scope and responsibility of your ability small, and
your faculties easily testable.

## Further Reading

You can always have a look at the official [best practices][cancan_practices] or
if you are feeling adventurous you can `gem open cancancan` and have a look into
the source code yourself!
{% endpost #9D9D9D %}

[cancan]: https://github.com/CanCanCommunity/cancancan/
[concerns]: http://api.rubyonrails.org/classes/ActiveSupport/Concern.html
[kind_of]: https://ruby-doc.org/core-2.4.1/Object.html#method-i-kind_of-3F
[cancan_practices]: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities:-Best-Practice

