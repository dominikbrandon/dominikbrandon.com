---
layout: post
cover: '/assets/images/cover-flashing-screen.webp'
navigation: True
title: 'Spock: helper methods for assertions'
date: 2022-08-02 18:00:00
tags: [Tips and tricks, Groovy, Spock, Testing]
subclass: 'post'
author: dominik
categories: dominik
description: 'My approach to using helper methods for assertions in Spock'
---

Whenever I write tests, I always try to do it in such a way that when it eventually fails -
the reason for that is clear and can be inferred based on the test output. In other words -
**when the test fails, it should tell you specifically what failed and why**, without the need
to use debugger or perform deep code analysis.

> Examples below base on [Spock 2.0](https://mvnrepository.com/artifact/org.spockframework/spock-core/2.0-groovy-3.0){:target="_blank" rel="noopener noreferrer"}.

#### ❌ What not to do

Oftentimes, however, I encounter similar constructs in the code to the one below:
{% highlight groovy %}
def "my test"() {
    given:
        def result = "abc"
    expect:
        helperMethod(result)
}

private boolean helperMethod(String a) {
    a.contains("a") && a.contains("d")
}
{% endhighlight %}

So what's the point, what's wrong with that? Let's put it in the code and check the output:
{% highlight console %}
Condition not satisfied:

helperMethod(result)
|            |
false        abc

	at MyTest.my test(MyTest.groovy:11)
{% endhighlight %}

Not helpful at all, is it? The only thing you know based on the output is that `helperMethod`
returned false, but *it's vague which exactly of the two conditions was the false one*.
How to improve this?

#### ✅ Do this instead

{% highlight groovy %}
def "my test"() {
    given:
        def result = "abc"
    expect:
        helperMethod(result)
}

private void helperMethod(String a) {
    assert a.contains("a")
    assert a.contains("d")
}
{% endhighlight %}

So now in the case of a failure, you'll see a neat output:
{% highlight console %}
Condition not satisfied:

a.contains("d")
| |
| false
abc

	at MyTest.helperMethod(MyTest.groovy:16)
	at MyTest.my test(MyTest.groovy:11)
{% endhighlight %}

This now tells you exactly what happened and even shows you the value of a variable that
undergoes the assertion. Well done!

#### 🧐 "The example is too made-up..."

Yeah, you're right, I totally feel you. The example was very simple for the sake of clarity.
Let's now look at the real-world one.

Let's say that your code sends events and in the tests you want to intercept these events,
store them in the memory and make assertions based on that. What did it look like when done in
a bad way?
{% highlight groovy %}
public record Event(int id, String body) { }

def "should send events"() {
    given:
        Event expectedEvent = new Event(1, "b")
    when:
        operationThatTriggersEvents()
    expect:
        eventWasSent(expectedEvent)
}

private boolean eventWasSent(Event expected) {
    return interceptedEvents.contains(expected)
}
{% endhighlight %}
{% highlight console %}
Condition not satisfied:

eventWasSent(expectedEvent)
|            |
false        Event[id=1, body=b]

	at MyTest.should send events(MyTest.groovy:15)
{% endhighlight %}

So... event was not sent, right? That's what it says, at least. But what
[`.contains()`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/List.html#contains(java.lang.Object)){:target="_blank" rel="noopener noreferrer"}
actually does is that it's checking the equality of an object. So it's not *event
was not sent*, but rather *this exact event was not sent*. 

So basically there are two different situations possible: one is that no events
were sent and the other one is that there were some events sent, but none of
them matched our expected one. Then which one actually occurred? We don't know
that, the test output does not provide any hint on it. We would need to run
the debugger in order to track down the issue, which is costly and can take
some time.

Let's try the better way and see the benefits.
{% highlight groovy %}
public record Event(int id, String body) { }

def "should send events"() {
    given:
        Event expectedEvent = new Event(1, "dog barked")
    when:
        operationThatTriggersEvents()
    expect:
        eventWasSent(expectedEvent)
}

private void eventWasSent(Event expected) {
    assert interceptedEvents.contains(expected)
}
{% endhighlight %}
{% highlight console %}
Condition not satisfied:

interceptedEvents.contains(expected)
|                 |        |
|                 false    Event[id=1, body=dog barked]
[Event[id=1, body=thief entered the house], Event[id=2, body=dog licked the thief]]

	at MyTest.eventWasSent(MyTest.groovy:19)
	at MyTest.should send events(MyTest.groovy:15)
{% endhighlight %}

Well, it seems like your dog's breed is a labrador retriever! If you want it to
scare away the burglar, then you should reconsider your choice 😀, you'll be
better off having a Dobermann or something.

Anyway, the point is that having this output - **you know exactly what happened
by just looking at it**! Isn't that great? Now that you know why the test failed,
you can proceed with tracking down a bug in your production code, without wasting
time on identifying the issue.

Take care about your logs - they should tell you the story.
