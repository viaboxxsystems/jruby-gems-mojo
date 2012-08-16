package de.viaboxx.gemsloader;

import org.jruby.RubyInstanceConfig;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Properties;

/**
 * Provides a convenient way to create a load path config suitable for a ScriptingContainer
 * instance that is able to access gems packaged with jruby-gems-plugin.
 */
public class GemLoader {

    /**
     * Creates a config with load paths adjusted to make gems discovery possible.
     * @return
     * @throws IOException
     */
    public RubyInstanceConfig configWithGems() throws IOException {
        RubyInstanceConfig config = new RubyInstanceConfig();
        List<String> loadPaths = loadPaths();
        config.setLoadPaths(loadPaths);
        return config;
    }

    /**
     * Creates a list of paths needed for a ScriptingContainer to be able to access gems bundled using the
     * jruby-gems-plugin maven plugin.
     * @return A list of path strings pointing to bundled gem roots.
     * @throws IOException If accessing a bundled gem fails despite it was mentioned in one of the
     * <code>gems-in-jar/gems-in-jar.properties</code> files found in the classpath.
     */
    public List<String> loadPaths() throws IOException {
        List<String> loadPaths = new ArrayList<String>();
        Enumeration<URL> gemDefinitions = classLoader().getResources("gems-in-jar/gems-in-jar.properties");
        while (gemDefinitions.hasMoreElements()) {
            Properties gemsProperties = new Properties();
            URL gemDefinitionsUrl = gemDefinitions.nextElement();
            gemsProperties.load(gemDefinitionsUrl.openStream());
            Enumeration gems = gemsProperties.propertyNames();
            while (gems.hasMoreElements()) {
                String gemPath = gemsProperties.getProperty((String) gems.nextElement());
                loadPaths.add(classLoader().getResource("gems/" + gemPath + "/lib").getPath());
            }
        }
        return loadPaths;
    }

    private ClassLoader classLoader() {
        return getClass().getClassLoader();
    }
}
