#!/usr/bin/env python

import pygtk
pygtk.require('2.0')
import gtk

class HelloWorld:
    def hello(self, widget, data=None):
        print "Hello World"

    def delete_event(self, widget, event, data=None):
        print "delete event occured"
        return False

    def destroy(self, widget, data=None):
        gtk.main_quit()

    def addButton(self, string, function, data=None):
        button = gtk.Button(string)
        button.connect("clicked", function, data)
        self.buttonArea.add(button)
        button.show()

    def createTextAreas(self):
        table = gtk.Table(2, 2, True)
        
        label = gtk.Label("Scaling")
        label.set_justify(gtk.JUSTIFY_LEFT)
        label.show()
        self.distanceText = gtk.TextBuffer()
        view = gtk.TextView(self.distanceText)
        table.attach(label, 0, 1, 0, 1)
        table.attach(view, 1, 2, 0, 1)
        view.show()    

        label = gtk.Label("File")
        label.set_justify(gtk.JUSTIFY_LEFT)
        label.show()
        self.fileText = gtk.TextBuffer()
        view = gtk.TextView(self.fileText)
        view.show()
        table.attach(label, 0, 1, 1, 2)
        table.attach(view, 1, 2, 1, 2)

        self.buttonArea.add(table)
        table.set_row_spacings(4)
        table.show()
        
    def __init__(self):
        self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        self.window.connect("delete_event", self.delete_event)
        self.window.connect("destroy", self.destroy)
        self.window.set_border_width(10)

        self.drawArea = gtk
        self.buttonArea = gtk.VBox()
        
        self.addButton("Add", self.addNode)
        self.addButton("Remove", self.removeSelected)
        self.addButton("Print", self.printTopology)
        self.addButton("Quit", self.quit);

        self.createTextAreas()
        
        self.window.add(self.buttonArea)
        self.buttonArea.show()
        self.window.show()

    def addNode(self, widget, data=None):
        print "add node"

    def removeSelected(self, widget, data=None):
        print "remove selected"

    def printTopology(self, widget, data=None):
        print "print topology"

    def quit(self, widget, data=None):
        gtk.main_quit()
        
    def main(self):
        gtk.main()



if __name__ == "__main__":
    hello = HelloWorld()
    hello.main()

   
