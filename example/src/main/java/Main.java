import de.viaboxx.gemsloader.GemLoader;
import org.jruby.embed.PathType;
import org.jruby.embed.ScriptingContainer;

import java.io.IOException;

public class Main {

    public static void main(String[] args) throws IOException {
        new Main().runApp();
    }

    private void runApp() throws IOException {
        // get a scriptin container to run our script within
        ScriptingContainer container = new ScriptingContainer();
        // set the load paths to make sure gems from gemfile are found
        container.setLoadPaths(new GemLoader().loadPaths());
        // run the script depending on the ruby gems
        container.runScriptlet(PathType.CLASSPATH, "hello_world.rb");
    }
}
