import de.viaboxx.gemsloader.GemLoader;
import org.jruby.embed.PathType;
import org.jruby.embed.ScriptingContainer;

import java.io.IOException;

public class Main {

    public static void main(String[] args) throws IOException {
        new Main().runApp();
    }

    private void runApp() throws IOException {
        ScriptingContainer container = new ScriptingContainer();
        container.setLoadPaths(new GemLoader().loadPaths());
        container.runScriptlet(PathType.CLASSPATH, "hello_world.rb");
    }
}
