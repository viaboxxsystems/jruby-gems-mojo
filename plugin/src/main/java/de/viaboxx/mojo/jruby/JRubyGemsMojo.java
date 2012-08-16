package de.viaboxx.mojo.jruby;

import org.apache.commons.io.FileUtils;
import org.apache.maven.execution.MavenSession;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.project.MavenProject;
import org.jruby.embed.LocalContextScope;
import org.jruby.embed.ScriptingContainer;

import java.io.*;
import java.net.URL;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


/**
 * Fetches all gems found in Gemfile, packages them into a jar, together with a descriptor file that can be used to
 * load bundled gems into a jruby runtime.
 *
 * @goal package-gems
 */
public class JRubyGemsMojo extends AbstractMojo {


    public static final String BUNDLER_GEM_PATH = "gems/bundler-1.1.3/lib";
    /**
     * Directory containing the build files.
     *
     * @parameter expression="${project.build.directory}"
     */
    private File buildDirectory;

    /**
     * Directory containing the build files.
     *
     * @parameter expression="${project.base.directory}"
     */
    private File baseDirectory;

    /**
     * The maven project.
     *
     * @parameter expression="${project}"
     * @readonly
     */
    private MavenProject project;

    /**
     * The Maven Session.
     *
     * @parameter expression="${session}"
     * @required
     * @readonly
     */
    protected MavenSession session;

    private static FilenameFilter dirsOnlyFilter = new FilenameFilter() {
        @Override
        public boolean accept(File file, String s) {
            return file.isDirectory();
        }
    };

    public void execute() throws MojoExecutionException, MojoFailureException {
        if (session.getSettings().isOffline()) {
            getLog().warn("Executed in offline mode => No Gems will be fetched!");
            return;
        }
        try {
            getLog().info("Downloading gems found in Gemfile...");
            fetchGems();
            moveGems();
            getLog().info("Preparing gem lookup file");
            prepareGems();
            cleanup();
        } catch (IOException e) {
            getLog().error(e);
            throw new MojoExecutionException(e.getMessage(), e);
        }
    }

    private void cleanup() throws IOException {
        FileUtils.cleanDirectory(new File(buildDirectory, "bundled-gems"));
    }

    private void moveGems() throws IOException {
        File gemsInJar = new File(buildDirectory, "bundled-gems/jruby/1.8/gems");
        FileUtils.copyDirectoryToDirectory(gemsInJar, new File(buildDirectory, "generated-resources"));
    }

    private void prepareGems() throws IOException {
        File gemsInJar = new File(buildDirectory, "generated-resources/gems-in-jar");
        FileUtils.forceMkdir(gemsInJar);
        File gemsSpec = new File(gemsInJar, "gems-in-jar.properties");
        createGemSpec(gemsSpec);
    }

    private void createGemSpec(File gemsSpec) throws IOException {
        Properties properties = createGemSpecProperties();
        gemsSpec.createNewFile();
        properties.store(new FileWriter(gemsSpec), "Gems for " + project.getArtifact().toString());
    }

    private Properties createGemSpecProperties() {
        Properties properties = new Properties();
        File gems = new File(buildDirectory, "generated-resources/gems");
        String[] gemDirs = gems.list(dirsOnlyFilter);
        for (String gemDir : gemDirs) {
            properties.put(bundleName(gemDir), gemDir);
        }
        return properties;
    }

    private String bundleName(String gemDir) {
        Pattern gemName = Pattern.compile("(.*)\\-\\d.*");
        Matcher matcher = gemName.matcher(gemDir);
        matcher.matches();
        return matcher.group(1);
    }

    private ScriptingContainer prepareRuntime() throws IOException, MojoExecutionException {
        ScriptingContainer container = new ScriptingContainer(LocalContextScope.THREADSAFE);
        List<String> loadPaths = new ArrayList<String>();
        URL bundler = getClass().getClassLoader().getResource(BUNDLER_GEM_PATH);
        if (bundler == null) throw new MojoExecutionException("Cannot find bundler gem at '" + BUNDLER_GEM_PATH + "'");
        loadPaths.add(bundler.getPath());
        getLog().info("Using Bundler from " + bundler.getPath());
        container.setLoadPaths(loadPaths);
        return container;
    }

    private void fetchGems() throws IOException, MojoExecutionException {
        ScriptingContainer container = prepareRuntime();
        InputStream resourceAsStream = getClass().getClassLoader().getResourceAsStream("install_gems.rb");
        container.put("$gem_file_location", new File(this.project.getFile().getParentFile(), "Gemfile").getAbsolutePath());
        container.put("$base_dir", new File(this.project.getFile().getParentFile(), "target"));
        container.runScriptlet(resourceAsStream, "install_gems.rb");
    }
}
