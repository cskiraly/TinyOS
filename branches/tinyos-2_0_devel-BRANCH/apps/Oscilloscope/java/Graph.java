/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

/* Panel for drawing mote-data graphs */
class Graph extends JPanel
{
    final static int MIN_WIDTH = 50;
    int gx0, gx1, gy0, gy1; // graph bounds
    int scale = 2; // gx1 - gx0 == MIN_WIDTH << scale
    Window parent;

    Graph(Window parent) {
	this.parent = parent;
	gy0 = 0; gy1 = 0xffff;
	gx0 = 0; gx1 = MIN_WIDTH << scale;
    }

    protected void paintComponent(Graphics g) {
	/* Repaint. Synchronize on Oscilloscope to avoid data changing.
	   Simply clear panel, draw Y axis and all the mote graphs. */
	synchronized (parent.parent) {
	    g.setColor(Color.BLACK);
	    g.fillRect(0, 0, getWidth(), getHeight());
	    int count = parent.moteListModel.size();
	    for (int i = 0; i < count; i++) {
		g.setColor(parent.moteListModel.getColor(i));
		drawGraph(g, parent.moteListModel.get(i));
	    }
	}
    }

    /* Draw graph for mote nodeId */
    protected void drawGraph(Graphics g, int nodeId) {
	SingleGraph sg = new SingleGraph(nodeId);

	if (gx1 - gx0 >= sg.width) // More points than pixels-iterate by pixel
	    for (int sx = 0; sx < sg.width; sx++)
		sg.nextPoint(g, (int)(sx / sg.xscale + gx0 + 0.5), sx);
	else // Less points than pixel-iterate by points
	    for (int gx = gx0; gx <= gx1; gx++)
		sg.nextPoint(g, gx, (int)(sg.xscale * (gx - gx0) + 0.5));
    }

    /* Inner class to simplify drawing a graph. Simplify initialise it, then
       feed it the X screen and graph coordinates, from left to right. */
    private class SingleGraph {
	int lastsx, lastsy, height, width, nodeId;
	double xscale, yscale;

	/* Start drawing the graph mote id */
	SingleGraph(int id) {
	    nodeId = id;
	    lastsx = -1;
	    lastsy = -1;
	    height = getHeight();
	    width = getWidth();
	    xscale = (double)width / (gx1 - gx0);
	    yscale = (double)height / (gy1 - gy0);
	}

	/* Next point in mote's graph is at x value gx, screen coordinate sx */
	void nextPoint(Graphics g, int gx, int sx) {
	    int gy = parent.parent.data.getData(nodeId, gx);
	    int sy = -1;

	    if (gy >= 0) { // Ignore missing values
		double rsy = height - yscale * (gy - gy0);

		// Ignore problem values
		if (rsy >= -1e6 && rsy <= 1e6)
		    sy = (int)(rsy + 0.5);

		if (lastsy >= 0 && sy >= 0)
		    g.drawLine(lastsx, lastsy, sx, sy);
	    }
	    lastsx = sx;
	    lastsy = sy;
	}
    }

    /* Update X-axis range in GUI */
    void updateXLabel() {
	parent.xLabel.setText("X: " + gx0 + " - " + gx1);
    }

    /* Ensure that graph is nicely positioned on screen. max is the largest 
       sample number received from any mote. */
    private void recenter(int max) {
	// New data will show up at the 3/4 point
	// The 2nd term ensures that gx1 will be >= max
	int scrollby = ((gx1 - gx0) >> 2) + (max - gx1);
	gx0 += scrollby;
	gx1 += scrollby;
	if (gx0 < 0) { // don't bother showing negative sample numbers
	    gx1 -= gx0;
	    gx0 = 0;
	}
	updateXLabel();
    }

    /* New data received. Redraw graph, scrolling if necessary */
    void newData() {
	int max = parent.parent.data.maxX();

	if (max > gx1 || max < gx0) // time to scroll
	    recenter(max);
	repaint();
    }

    /* User set the X-axis scale to newScale */
    void setScale(int newScale) {
	gx1 = gx0 + (MIN_WIDTH << newScale);
	scale = newScale;
	recenter(parent.parent.data.maxX());
	repaint();
    }

    /* User attempted to set Y-axis range to newy0..newy1. Refuse bogus
       values (return false), or accept, redraw and return true. */
    boolean setYAxis(int newy0, int newy1) {
	if (newy0 >= newy1 || newy0 < 0 || newy0 > 65535 ||
	    newy1 < 0 || newy1 > 65535)
	    return false;
	gy0 = newy0;
	gy1 = newy1;
	repaint();
	return true;
    }
}
