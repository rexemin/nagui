module gui.draw.network;

import tkd.tkdapplication;

class NetworkWindow {
    private string title;
    private Window parent, networkWindow;
    private Canvas surface;

    this(Window parent)
    {
        this.parent = parent;
        this.title = "Network algorithms";
    }

    private void close(CommandArgs args)
    {
        this.networkWindow.withdraw();
    }

	public void open(CommandArgs args)
	{
		this.networkWindow = new Window(this.parent, this.title)
			.setGeometry(1021, 576, 50, 50)
            .setProtocolCommand(WindowProtocol.deleteWindow, &this.close);

        this.surface = new Canvas(this.networkWindow)
			.pack(10, 0, GeometrySide.top, GeometryFill.both);
	}
}
