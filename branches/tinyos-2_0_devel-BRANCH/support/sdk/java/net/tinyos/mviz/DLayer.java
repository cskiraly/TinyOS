/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.mviz;

// DDocument.java

import java.awt.*;

import javax.imageio.ImageIO;
import javax.swing.*;

import java.util.*;
import java.awt.event.*;
import java.io.*;

import javax.swing.border.Border;
import javax.swing.border.LineBorder;
import javax.swing.table.*;

import java.awt.image.*;


// Standard imports for XML
import javax.xml.parsers.*;
import org.xml.sax.*;
import org.w3c.dom.*;




public class DLayer extends JPanel implements ActionListener{
	
    public static final int MOTE = 0;
    public static final int LINK = 1;
    public static final int FIELD = 2;
    private static final Color[] COLORS = {
	new Color(231, 220, 206),
	new Color(250, 210, 99),
	new Color(209, 230, 179)
    };
	
    private int type;
    protected int index;
    protected int zIndex;
    private JLabel label;
    private JCheckBox check;
    private String[][] DISPLAYS = { {"circle", "img", "txt"}, {"line", "line+label", "label"}, {"color"}};
    private JComboBox displays;
	
    private ArrayList models;
    protected APanel canvas;
	
    private JButton up;
    private JButton down;
	
    protected int paintMode = 0;
    static public final int OVAL = 0;
    static public final int IMG = 1;
    static public final int TXT_MOTE = 2;
	
    private int default_width = 600;
    private int default_height = 600;
	
    private DDocument parent;
	
    public DLayer(int zIndex, int index, String label, int type, DDocument parent, ArrayList models){
	this.parent = parent;
	this.type = type;
	this.models = models;
	this.zIndex = zIndex;
	this.index = index;
		
		
	canvas = new APanel();
	canvas.setLayout(null);
	canvas.setPreferredSize(new Dimension(default_width, default_height));
	canvas.setSize(default_width, default_height);
	canvas.setOpaque(false);
	parent.layers.addComponentListener(canvas);
	parent.layers.add(canvas);
		
		
	GridLayout layout = new GridLayout(0, 5);
	setLayout(layout);
	setMaximumSize(new Dimension(350, 25));
	setDoubleBuffered(true);
	setBackground(COLORS[type]);
	setBorder(new LineBorder(new Color(155, 155, 155)));
		
	check = new JCheckBox();
	up = new JButton("up");		
	down = new JButton("down");		
	this.label = new JLabel(label, JLabel.LEFT);
	displays = new JComboBox(DISPLAYS[type]);
		
	up.setMaximumSize(new Dimension(20, 15));
	down.setMaximumSize(new Dimension(20, 15));
		
	check.addActionListener(this);
	up.addActionListener(this);
	down.addActionListener(this);
	displays.addActionListener(this);
		
	add(check);
	add(up);
	add(down);
	add(this.label);
	add(displays);
		

	canvas.addMouseListener( new MouseAdapter() {
		public void mousePressed(MouseEvent e) {
		    //			    if (selected != null){ // Deselect current shape, if any.
		    //			        DShape oldSelected = selected;
		    //			        selected = null;
		    //			        oldSelected.repaint();
		    //			    }
		}
	    });
		
    }
	
    public void actionPerformed(ActionEvent e) {
	if (e.getSource() == check) {
	    if (check.isSelected()){
		parent.selectedFieldIndex = index;
		redrawLayer();
		System.out.println("redraw index " +zIndex +"on layer" + parent.layers.getLayer(canvas));
	    }
	} else if (e.getSource() == up){
	    System.out.println("up " + this.label.getText());
	    parent.navigator.moveLayerUp(this.zIndex);
	} else if (e.getSource() == down){
	    System.out.println("down " + this.label.getText());
	    parent.navigator.moveLayerDown(this.zIndex);
	} else if (e.getSource() == displays){
	    String selected = (String)displays.getSelectedItem();
	    if (selected=="circle"){
		paintMode = OVAL;
	    } else if (selected=="img"){
		paintMode = IMG;        		
	    } else if (selected=="txt"){
		paintMode = TXT_MOTE;        		
	    }
	    System.out.println(selected);
	    redrawLayer();
	}
    }

    public void init(){
	if (type==LINK){
	    addLinks(true);
	} else {
	    addMotes(true);
	}
    }
	
    private void addLinks(boolean paint){
	Iterator it = models.iterator();
	while(it.hasNext()){
	    DLink mm = (DLink) it.next();
	    canvas.add(mm);
	    if (paint) mm.repaint();
	}    	
    }
    private void addMotes(boolean paint){
	Iterator it = models.iterator();
        while(it.hasNext()){
	    DShape m = new DMote((DMoteModel) it.next(), this.parent, this);
            canvas.add(m/*, 0*/);
            //setSelected(m);
            if (paint) m.repaint();
	} 	    
    }
	
	
    public void PaintScreenBefore() 
    {
        Graphics g = this.canvas.getGraphics();
        Dimension d = this.canvas.getSize();
      
	//        g.setColor(new Color(50, 50, 150));
	//        g.fillRect(0,0,d.width,d.height);
  

        int x = 0;
        int y = 0;
        int step = 5;  

        for(;x < d.width; x += step){
            for(y = 0;y < d.height; y += step){
                double val = 0;
                double sum = 0;
                double total = 0;
                double min = 10000000;
                Iterator it = models.iterator();
                while(it.hasNext()){
                    DMoteModel m = (DMoteModel) it.next();
                    double dist = distance(x, y, m.x, m.y);   
                    if(true){ //121
                        if(dist < min) min = dist;
                        val += ((double)m.getValue(index))  / dist /dist;
                        sum += (1/dist/dist);
                    }
                }
                int reading = (int)(val / sum);
                reading = reading >> 2;
                if (reading > 255)
                    reading = 255;
                g.setColor(new Color(reading, reading, reading));
                g.fillRect(x, y, step, step);
            }
        }
    }

    public double distance(int x, int y, int x1, int y1){
        return Math.sqrt( (x-x1)*(x-x1)+(y-y1)*(y-y1));
    }
	
    protected void redrawLayer(){
	if (check.isSelected()){
	    canvas.setVisible(true);
	    if 	(type==FIELD){
		DLayer.this.PaintScreenBefore();
	    } else {
		canvas.repaint();
	    }
	} else {
	    canvas.setVisible(false);
	    canvas.repaint();
	}
	
    }
    
    private class APanel
	extends JPanel
	implements ComponentListener {
	public void componentResized(ComponentEvent e) {
	    JLayeredPane src = (JLayeredPane)e.getSource();
	    setSize(src.getWidth(), src.getHeight());
	    redrawLayer();
	}
	public void componentHidden(ComponentEvent arg0) {
	}
	public void componentMoved(ComponentEvent arg0) {
	}
	public void componentShown(ComponentEvent arg0) {
	}
    }
}
