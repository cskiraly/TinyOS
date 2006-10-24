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


// DShape.java
import java.awt.*;
import java.util.*;
import javax.swing.*;
import java.awt.event.*;

abstract class DShape 
extends JComponent 
implements DMoteModelListener
{
	
	protected DMoteModel model;
	protected DDocument document;
	public Image img;
	

	
    // remember the last point for mouse tracking
	private int lastX, lastY;
	protected DLayer layer;
	
	// Move or Resize ?
	private int action;
    private static final int MOVE = 0;
	//=========================================================================//
	public DShape(DMoteModel model, DDocument document, DLayer layer) {
		super();
		this.model = model;
		this.img = model.root.icon;
		this.document = document;
		this.layer = layer;
		model.addListener(this);
		
		
		// Mouse listeners.
		addMouseListener( 
		        new MouseAdapter() 
		        {
		            public void mousePressed(MouseEvent e) {
		                selected();
		                lastX = e.getX()+getX();
		                lastY = e.getY()+getY();
		                
		                if (e.isControlDown()){ 
		                }else if(e.isAltDown()){ 
		                }else if(e.isShiftDown()){
		                }else{ DetermineAction(lastX, lastY); }			    
		            }
		        }
		);

		addMouseMotionListener( 
		        new MouseMotionAdapter() 
		        {
		            public void mouseDragged(MouseEvent e) {
		                
		                int x = e.getX()+getX();
		                int y = e.getY()+getY();
		                // compute delta from last point
		                int dx = x-lastX;
		                int dy = y-lastY;
		                lastX = x;
		                lastY = y;
		                
		                switch(action){
		                case MOVE: DoAction(dx, dy); break;
		                }
		            }
		        }
		);
		
		synchToModel();		
	}
   
	//=========================================================================//
	public DMoteModel getModel() {
		return(model);
	}
	
	//=========================================================================//
	public void shapeChanged(DMoteModel changed, int type) {
	    synchToModel();
	    repaint();
	}
	//=========================================================================//
	public abstract void paintShape(Graphics g);
	//=========================================================================//
    public void paintComponent(Graphics g) {
	    super.paintComponent(g);
    
        
        g.setColor(model.getColor(layer.index));
	    paintShape(g);
	    if (document.getSelected() == this){
	        // Paints the knobs.
	        Color old = g.getColor();
	        g.setColor(old);
	    }
	}
	//=========================================================================//
	private void DetermineAction(int x, int y){
        action = MOVE;	        
	}
	//=========================================================================//
	private void DoAction(int dx, int dy){
	    model.applyDeltas(dx, dy);
	}
	//=========================================================================//
	private void synchToModel(){
		int x=0, y=0, w=0, h=0;
		switch(layer.paintMode){
		case DLayer.IMG:
	    	x = model.getLocX();
	    	y = model.getLocY();
	    	//w = model.getWidth(layer.index);
	    	//h = model.getHeight(layer.index);
	    	w = 250;
	    	h = 250;
			break;
		case DLayer.OVAL:
			x = model.getLocX();
	    	y= model.getLocY();
	    	w = 10;
	    	h = 10;
			break;
		case DLayer.TXT_MOTE:
			x = model.getLocX();
	    	y= model.getLocY();
	    	w = 250;
	    	h = 250;
			break;
		}
	    setBounds(x, y, w, h);
	}
	//=========================================================================//
	private void selected(){
	    document.setSelected(this);	    
	}

}



