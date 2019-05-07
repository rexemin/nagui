/**
 *
 */
module gui.menu;

import tkd.tkdapplication;

class Application: TkdApplication {
	private void exitCommand(CommandArgs args)
	{
		this.exit();
	}

	override protected void initInterface()
	{
		import gui.draw.network;
		import std.string: format;
		auto versionString = "v0.1";

		// Window.
		this.mainWindow.setTitle(format("NaGUI %s", versionString))
			.setGeometry(1024, 576, 25, 25); // 16:9 resolution.
		this.setTheme(Theme.clam);

		// Heading.
		auto headingFrame = new Frame(2, ReliefStyle.flat)
			.pack(10, 0, GeometrySide.top, GeometryFill.both);
		auto appTitle = new Label(headingFrame, "NaGUI (Network algorithms with a GUI)")
			.pack(10);
		auto aboutLabel = new Label(headingFrame, "Made by Ivan A. Moreno Soto.")
			.pack(10);
		auto versionLabel = new Label(headingFrame, versionString)
			.pack(10);

		auto titleOptionsSep = new Separator()
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// Row of options.
		auto nw = new NetworkWindow(this.mainWindow);

		auto optionsFrame = new Frame(2, ReliefStyle.flat)
			.pack(10, 0, GeometrySide.top, GeometryFill.both);

		auto graphButton = new Button(optionsFrame, "Graphs")
			.pack(10);
		auto digrahpButton = new Button(optionsFrame, "Directed graphs")
			.pack(10);
		auto networkButton = new Button(optionsFrame, "Networks")
			.setCommand(&nw.open)
			.pack(10);

		auto optionsExitSep = new Separator()
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// Exit.
		auto exitFrame = new Frame(1, ReliefStyle.flat)
			.pack(10, 0, GeometrySide.top, GeometryFill.both);
		auto exitButton = new Button(exitFrame, "Exit")
			.setCommand(&this.exitCommand)
			.pack(10);
	}
}
