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

Technically, adding `src/main/ruby` is not needed, but i regard putting ruby source 
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
This is intended to be used by you when embedding ruby into a java project.

jruby-gems-plugin-example
-------------------------
An example project showing how to use the above projects in your own java projects.