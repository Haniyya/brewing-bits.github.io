---
layout: post
title:  "A way to split up big merge- or pull-requests"
date:   2017-09-10 09:20:00 +0100
categories: blog
tags: ['git', 'vim', 'rails', 'programming']
published: true
comments: true
excerpted: |
  Working in a team, and having someone review your code, can take quite a
  while. Especially if your Merge- or Pull-Request makes a lot of changes. Here
  I'll show a way to split one big merge request into several small, easy to
  review ones.

# Does not change and does not remove 'script' variables
script: [post.js]
---

Working in a team, and having someone review your code, can take quite a
while. Especially if your Merge- or Pull-Request makes a lot of changes. Here
I'll show a way to split one big merge request into several small, easy to
review ones.

* Do not remove this line (it will not be displayed)
{: toc}

## What we'll use

In this article, we'll use [git][git] and, since it's my preferred editor,
[vim][vim] (or in my case [neovim][neovim] to be more specific). But I'll show a
way to do this independent of vim.

## The problem

Say you have a big feature prepared. You've written great, succinct code. But
you had to touch a lot of files in your system. Now if your team uses some kind
of project management like [Gitlab][gitlab] or [Github][github], you usually
will submit your changes using a "Merge-Request" (or "Pull-Request" in the case
of Github). Let's make a more concrete example using a `rails` application:

1. You added a new model and tests for it
1. You added a concern so that other models could use your new one.
1. You added a controller and routes for the new resource.
1. You changed the views to incorporate those changes.
1. You updated the documentation to include your changes.

If you have all these changes on one branch, lets call it `112-new-feature-branch`
(where `112` might be the issue number you are solving),
you could have touched around 20+ files and added a few hundred lines of code
(remember writing enough tests to make sure it all works). Not only will this
take a long time to review, it will be a lot for your colleagues to grasp. To
make it easier on them (and to encourage your colleagues to actually have a look
at your changes), we are going to split this big branch into 5 distinct ones.

## The solution

If you follow some of `git`s best practices, you may have heard of 
> Commit often, push once.

This principal will be very useful now.
First, open a new branch.

```bash
$ git checkout -b 112-1-new-feature-model
```

You now have an 'empty' branch, based on the `master` branch of you repository.
What we want to do, is isolate all changes related to the `model` we added in
our branch.

### Starting the rebase

We are going to do that using the infamous `git rebase`:
```bash
$ git rebase -i HEAD
```
**Note**: The `-i` option here is short for `--interactive` and is important
since it will open up a `rebase-todo` file for us.

What you should see now is something like this:
```git
noop

# Rebase von [Commit-SHA]..[Commit-SHA] auf [Commit-SHA] (1 Kommando)
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```
**Note**: You'll have to set the `EDITOR` environment-variable beforehand (or
just fix it in your `.bashrc`). Since I set `EDITOR=nvim` in my `.bashrc`, the
command above opens up neovim for me.

### Getting the right commits

Now comes the clever part, we are going to pick out all the commits we care
about from `112-new-feature-branch` using the following command:
```bash
git log --oneline --reverse HEAD..112-new-feature-branch -- app/models/ spec/models
```
Woah thats quite the line! Let's dissect it first:
1. `git log` shows a log of what you have done in your project.
1. `--online` formats the output from a few lines (including author
   and time of commit), to just "[sha-hash-of-commit] [description-of-commit]"
1. `--reverse` reverses the log output chronologically (so oldest commit first,
   newest last).
1. `112-new-feature-branch..HEAD` shows the difference in commits from your
   current branch (`HEAD`) and the branch you are interested in
   `112-new-feature-branch`.
1. `-- app/models/ spec/models` Only show commits that changed files in `app/models/` or `spec/models`
    So that we confine the changes to our model and its tests.

Now if you are using vim (or vi or neovim) you can put the results of this
command directly into your `rebase-todo` (which was opened when starting the
rebase) using the `:r` command like so:
```bash
:r !git log --oneline --reverse HEAD..112-new-feature-branch -- app/models/
```
If you're not using a vi-like editor, you can either pipe the results into your
clipboard:
```bash
# Assuming xsel is your clipboard of choice
git log --oneline --reverse HEAD..112-new-feature-branch -- app/models/ spec/models | xsel
```
Or put it into a new file:
```bash
# Assuming there is a tmp directory for you to put stuff in.
git log --oneline --reverse HEAD..112-new-feature-branch -- app/models/ spec/models > tmp/models-todo
```
and copy it from there manually.

### Check which commits you actually want

Your 'rebase-todo' file now should look somewhat like this:

```git
noop

c4f74d0 Added new model specs.
875f2f3 Added migration for new model.
88dbbd7 Added model for new model...
49ef7de Fixed a thing in specs.
be695ff Changed association.
1057525 Revert "Fixed a thing in specs."
3e638e9 Really fixed a thing in the specs.

# Rebase von [Commit-SHA]..[Commit-SHA] auf [Commit-SHA] (1 Kommando)
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```

Now you have a chance to go though your todo once again. First you should remove
the `noop` from above, since you actually do something now. Second you should
check the diffs of the sha-hashes.

**Note**: If you are using vim, you might already have the [`fugitive`][fugitive] plug-in.
If you haven't changed the standard configuration, you can just move your cursor
over the sha-hashes and press `K` (note that its capitalized) to see the diff of
that commit.

If you don't have `fugitive` or don't use vim, you can check the diff using `git
show SHA-HASH` (ex: `git show c4f74d0`), which shows the commits data.

Now you can prepend and even rearrange the commits (:warning: Be careful
rearranging or leaving out commits, you might have to fix conflicts later).

### The TODO-file's done

When you're done, the file should look like this:

```git
pick c4f74d0 Added new model specs.
pick 875f2f3 Added migration for new model.
pick 88dbbd7 Added model for new model...
drop 49ef7de Fixed a thing in specs.
drop 1057525 Revert "Fixed a thing in specs."
pick be695ff Changed association.
pick 3e638e9 Really fixed a thing in the specs.

# Rebase von [Commit-SHA]..[Commit-SHA] auf [Commit-SHA] (1 Kommando)
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```

Now you can save and exit the editor and git will try to execute the rebase. If
you have conflicts you can fix them just like you do with merges and then
continue using `git rebase --continue`.

If you feel like something is going
terribly wrong (for example you have a bunch of conflicts in just a few
commits), you can abort the rebase using `git rebase --abort` and it will be
like nothing ever happened.

### The first step is taken

That's the basic idea. Now you can make a new branch from the one you're on
```bash
git checkout -b 112-2-new-feature-concern
```
And repeat the process
```bash
git log --oneline --reverse HEAD..112-new-feature-branch -- app/concerns spec/concerns
```

Once you've made all the branches you want, you can check if you forgot any
commits by doing 
```bash
git show-branch 112-5-new-feature-documentation 112-new-feature-branch
```
Which will show you the difference between those two branches.
Once you have pushed all 5 branches, remember to arrange the merge requests in a
way that one branch always merges into the previous, while the first
(`112-1-new-feature-model` in our case), merges directly into master.

## Conclusion

To recap:
1. Start a new branch.
1. Start an interactive rebase on `HEAD`.
1. Get the commits you want.
1. Review the commits you want.
1. Execute the rebase.
1. Repeat step 1 until all commits are distributed to the differing branches.

Now that you have 5 small requests to review instead of a single big one, your
colleagues will hopefully have an easier time approving the changes you've made.

{% endpost #9D9D9D %}


[vim]: https://vim.sourceforge.io/
[git]: https://git-scm.com/
[neovim]: https://neovim.io/
[gitlab]: https://about.gitlab.com/
[github]: https://github.com
[fugitive]: https://github.com/tpope/vim-fugitive
