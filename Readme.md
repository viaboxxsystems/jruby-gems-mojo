JRuby Gems Mojo
===============
Adds support for embedding gems into maven-build java projects. The basic idea is to 
enable you to develop portions of a maven-based java project using jruby and ruby gems 
without hassles.

How it works (high-level)
-------------------------
All gem dependencies are managed using bundler, using a standard Gemfile that is expected 
to reside right next to your pom.xml file. Effectively, we are using a 
`bundle install --deployment` call to fetch gems into the project, so you'll need to run 
bundle once to generate a `Gemfile.lock`, which you should check in to pin your dependencies.

Fetched dependencies are put into `target/generated-resources/gems-in-jar/gems`.

How to adopt your pom.xml
-------------------------
You can find a working example in the _jruby-gems-plugin-example_ project. The conventions are:

* Ruby source code resides in `src/main/ruby`
* You are using a standard `Gemfile`, placed next to your `pom.xml`

First up, you'll need to add the Mojo to your pom.xml:

    <plugin>
        <groupId>de.viaboxx</groupId>
        <artifactId>jruby-gems-plugin</artifactId>
        <version>1.0-SNAPSHOT</version>
        <executions>
            <execution>
                <phase>generate-resources</phase>
                <goals>
                    <goal>package-gems</goal>
                </goals>
            </execution>
        </executions>
    </plugin>

We have to tell maven where to find ruby scripts and gems:

    <resources>
        <resource>
            <directory>src/main/ruby</directory>
        </resource>
        <resource>
            <directory>src/main/resources</directory>
        </resource>
        <resource>
            <directory>target/generated-resources</directory>
        </resource>
    </resources>

Technically, adding `src/main/ruby` is not needed, but we regard putting ruby source 
code into src/main/ruby as good practice.

Next is adding a Gemfile to your project, add needed dependencies and run `bundle install` to 
create a `Gemfile.lock` file.

After that, a simple `mvn install` fetches needed gems and puts them into 
`target/generated-resources/gems-in-jar`.

Directions
==========
This project consists of three sub-projects.

jruby-gems-plugin
-----------------
Provides a Mojo for Maven that is able to download gems using Bundler and packages
them together with your app into a jar.

gem-loader
----------
Small helper library that shows how to get hold of a ScriptingContainer capable of
using packaged gems.
This is intended for use when embedding ruby into a java project.

jruby-gems-plugin-example
-------------------------
An example project showing how to use the above projects in your own java projects.

How gems are bundled
====================
Bundled gems are put into `target/gems`. Additionally, a properties file is put into
`target/gems-in-jar/gems-in-jar.properties` containing name and version of the bundled gems. The information found here
is used to construct load paths by the gem-loader.

It is possible to have more than one project in your classpath that uses bundled gems, but as the time of this writing,
there is nothing in place to stop you putting multiple versions of the same gem into the load path. [see the todo file for details](/todo.md)

Known limitations
=================

Bundler groups
--------------

There are some limitations what can be done within the Gemfile:
* there is no support for selection groups yet

Multiple jars with gem dependencies within classpath
----------------------------------------------------
By now, we assume that we have only one jar with gem dependencies within the classpath. If there is more 
than one jar with gem dependencies decalred, all jruby script configurations get teh sum of all declared,
wich is very likely not what you want. Adding a namespacing-lie feature for this would be possible, but I 
would prefer to to this only if really needed. Add an issue if you need this so we can discuss possible 
solutions so we can add this feature.

Build Status
============

[![Build Status](https://secure.travis-ci.org/viaboxxsystems/jruby-gems-mojo.png)](http://travis-ci.org/viaboxxsystems/jruby-gems-mojo])