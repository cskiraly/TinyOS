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

import javax.swing.table.*;
import java.awt.image.*;


// Standard imports for XML
import javax.xml.parsers.*;
import org.xml.sax.*;
import org.w3c.dom.*;


public class DNavigate extends JPanel implements ActionListener{
    private DDocument parent;
    protected ArrayList<DLayer> layers = new ArrayList<DLayer>();
    private int zIndex;
    private int _tmp_i = 0;
    
    public DNavigate(Vector<String>label_motes, Vector<String> label_links, DDocument parent){
		this.parent = parent;
		BoxLayout layout = new BoxLayout(this,BoxLayout.PAGE_AXIS);
		this.setLayout(layout);
		this.setBackground(new Color(10,100,200));
		
		int total = 2 * label_motes.size() + label_links.size();
		zIndex = (total + 1) * 100;
		
		this._tmp_i = 0;
		addLayer(label_motes, DLayer.MOTE, parent.motes);
		addLayer(label_links, DLayer.LINK, parent.links);
		addLayer(label_motes, DLayer.FIELD, parent.motes);      
		updateLayerIndex();
        
	}
	
	private void addLayer(Vector<String> labels, int type, ArrayList models){
	    for (int i=0; i<labels.size(); i++, _tmp_i++){
		DLayer d = new DLayer(_tmp_i, i, labels.elementAt(i), type, parent, models);
		this.add(d);
		//this.add(d, new Integer(zIndex));
		zIndex = zIndex - 100;
		layers.add(d);
	    }
	}
	
	private void updateLayerIndex(){
		int length = layers.size();
		Iterator it = layers.iterator();
		int i = 0;
		while (it.hasNext()){
			DLayer d = (DLayer) it.next();
			d.zIndex = i;
			parent.layers.setLayer(d.canvas, length - i);
			++i;
        }
	}
	
	public void redrawNavigator(){
		Iterator it = layers.iterator();
		while (it.hasNext()){
			remove((DLayer) it.next());
        }
		it = layers.iterator();
		while (it.hasNext()){
			add((DLayer) it.next());
        }
		revalidate();
		
	}
	
	public void moveLayerUp(int zIndex){
		if (zIndex == 0){ return; }
		DLayer d = (DLayer) layers.remove(zIndex);
		layers.add(zIndex-1, d);
		updateLayerIndex();
		redrawNavigator();
	}
	
	public void moveLayerDown(int zIndex){
		if (zIndex == layers.size()-1){ return; }
		DLayer d = (DLayer) layers.remove(zIndex);
		layers.add(zIndex+1, d);
		updateLayerIndex();
		redrawNavigator();
	}
	
	public void init(){
		Iterator it = layers.iterator();
		while (it.hasNext()){
			((DLayer) it.next()).init();
        }
	}
	
	public void actionPerformed(ActionEvent e) {
		// TODO Auto-generated method stub
		
	}
}
