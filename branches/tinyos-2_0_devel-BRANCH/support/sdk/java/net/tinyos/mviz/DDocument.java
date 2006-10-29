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
import java.awt.event.*;
import java.awt.image.*;
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.util.*;

import javax.imageio.ImageIO;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;

import net.tinyos.message.*;

public class DDocument
    extends JPanel 
    implements ActionListener{    

    protected String directory;
    protected JPanel canvas;
    protected Vector<DLayer> layers;
	
    private Color currentColor;
	
    public float[] maxValues;
    public int selectedFieldIndex;
    public int selectedLinkIndex;
    public ImageIcon icon;
    public Image image;
	
	
    public DNavigate navigator;
	
	
	
    public Color getColor(){ return currentColor; }
	
	
    //=========================================================================//
    public Vector<String> sensed_motes;
    public Vector<String> sensed_links;
	
    public ArrayList moteModels;
    public ArrayList linkModels;
    
	
	
    //	private JComboBox selectMotes;
    //	private JComboBox selectLinks;
	
	
    private JTextField jText;
    private DrawTableModel tableModel;
    private JTable jTable;
	
    private String[] toStringArray(Vector<String> v) {
	String[] array = new String[v.size()];
	for (int i = 0; i < v.size(); i++) {
	    array[i] = v.elementAt(i);
	}
	return array;
    }
    
    public DDocument(int width, int height, Vector<String> fieldVector, Vector<String> linkVector, String dir) {
	super();
	layers = new Vector<DLayer>();
	directory = dir;
	
	setOpaque(false);
	setLayout(new BorderLayout(6,6));
	try{ UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
	} catch (Exception ignore){}
		
	selectedFieldIndex = 0;
	selectedLinkIndex = 0;
	canvas = new JPanel();
	canvas.setLayout(null);
	canvas.setDoubleBuffered(true);
	canvas.setPreferredSize(new Dimension(width, height));
	canvas.setMinimumSize(new Dimension(width, height));
	canvas.setSize(new Dimension(width, height));
	canvas.setOpaque(false);
	canvas.setBorder(new SoftBevelBorder(SoftBevelBorder.LOWERED));
	add(canvas, BorderLayout.CENTER);

	
	// toArray() should work, but for some reason it is returning [Ljava.lang.Object
	// instead of [Ljava.lang.String
	sensed_motes = fieldVector;
	sensed_links = linkVector;
	moteIndex = new HashMap<Integer, DMoteModel>();
	linkIndex = new HashMap<String, DLinkModel>();
		
	String name = directory + "/images/tmote_sky.jpg";
	name = "tmote_sky.jpg";
	System.out.println(name);
	URL imgURL = getClass().getResource(name);
	icon = new ImageIcon(directory + "/images/tmote_sky.jpg", "mote");
	try {
	    System.out.println(name + " " + imgURL);
	    image = Toolkit.getDefaultToolkit().getImage(imgURL);
	}
	catch (Exception e) {
	    System.out.println(e);
	}
	System.out.println(name);
		
	// Make drawing canvas
	//----------------------------------------
		
	//	canvas.addMouseListener( new MouseAdapter() {
	//		public void mousePressed(MouseEvent e) {
	//			    if (selected != null){ // Deselect current shape, if any.
	//			        DShape oldSelected = selected;
	//			        selected = null;
	//			        oldSelected.repaint();
	//			    }
	//	    }
	//	});
		
	canvas.addComponentListener(new ComponentListener(){
		public void componentResized(ComponentEvent e) {
		    navigator.redrawAllLayers();
		}
		public void componentHidden(ComponentEvent arg0) {
		}
		public void componentMoved(ComponentEvent arg0) {
		}
		public void componentShown(ComponentEvent arg0) {
		}			
	    });

		
		
	// Make control area
	JPanel west = new JPanel();
	west.setDoubleBuffered(true);
	west.setLayout(new BoxLayout(west, BoxLayout.Y_AXIS));
	add(west, BorderLayout.WEST);
		
	//------------------------------------
	currentColor = Color.GRAY;
	//------------------------------------
	// BUTTONS and Other Controls: 
	//------------------------------------
		
		
		
		
	/*String[] labelStrings = {
	  "Nodes",
	  "Links"
	  };
	  JLabel[] labels = new JLabel[labelStrings.length];
	  JComponent[] fields = new JComponent[labelStrings.length];
		
	  for (int i = 0; i < labelStrings.length; i++) {
	  JTextField jt = new JTextField();
	  jt.setMaximumSize(new Dimension(350,150));
	  jt.addActionListener(this);
			
	  fields[i] = jt;
	  labels[i] = new JLabel(labelStrings[i], JLabel.TRAILING);
	  labels[i].setLabelFor(fields[i]);
	  west.add(labels[i]);
	  west.add(fields[i]);
	  }*/
		
		
	navigator = new DNavigate(sensed_motes, sensed_links, this);
	west.add(navigator);

		
	//------------------------------------
	// Table.
	west.add(Box.createVerticalStrut(10));
	tableModel = new DrawTableModel(sensed_motes);
	jTable = new JTable(tableModel);
	jTable.setAutoResizeMode(JTable.AUTO_RESIZE_ALL_COLUMNS);
	JScrollPane scroller = new JScrollPane(jTable);
	scroller.setPreferredSize(new Dimension(350, 200));
	scroller.setMinimumSize(new Dimension(350, 200));
	scroller.setSize(new Dimension(350, 200));
	west.add(scroller);
		
		
	//		
	//		JLabel a = new JLabel(new ImageIcon(icon));
	//		a.setBounds(5,5,100,100);
	//		canvas.add(a);
    }

    /*public void repaint() {
      super.repaint();
      System.out.println("Repainting navigator?");
      if (navigator != null &&
      jTable != null &&
      canvas != null) {
      navigator.repaint();
      jTable.repaint();
      canvas.repaint();
      System.out.println("Repainting all three.");
      }
      }*/
    
    //=========================================================================//
    public void actionPerformed(ActionEvent e) {
	// e.getSource() is the originator of the action --
	// if-logic to check which one it was
		
		
	//navigator.repaint();
	//canvas.repaint();
    }
    //=========================================================================//
    private void zMove(int direction){
	//if (selected == null) return;
	//canvas.remove(selected);
	//canvas.add(selected, direction);
	//selected.repaint();
	tableModel.updateTable();
    }
    //=========================================================================//
    public int width_canvas = 600;
    public int height_canvas = 600;
	
    protected ArrayList<DMoteModel> motes = new ArrayList<DMoteModel>();
    protected ArrayList<DLinkModel> links = new ArrayList<DLinkModel>();
    protected HashMap<Integer, DMoteModel> moteIndex;
    protected HashMap<String, DLinkModel> linkIndex;
	
    private void createRandomMotes(){
	Random rand = new Random();
	int total = rand.nextInt(26)+10;
	for (int i=0; i<total; i++){
            DMoteModel m = new DMoteModel(i, rand, this);
	    motes.add(m);
	    moteIndex.put( new Integer(i), m);
	    tableModel.add(m);
	    //addShape(m, true); 
	}
		
    }
	
    private void createRandomLinks(){
	Random rand = new Random();
	int size = motes.size();
	int total = rand.nextInt(size)*3;
		
	for (int i=0; i<total; i++){
	    int m1 = rand.nextInt(size);
	    int m2 = rand.nextInt(size);
	    if (m1==m2) continue;
			
	    DLinkModel m = new DLinkModel((DMoteModel)motes.get(m1), (DMoteModel)motes.get(m2), rand, this);
	    links.add(m);
	    //addLink(m, true); 
	}
		
    }
	
    //=========================================================================//
    // Provided default ctor that calls the regular ctor
    public DDocument(Vector<String> fieldVector, Vector<String> linkVector) {
	this(300, 300, fieldVector, linkVector, ".");	 // this syntax calls one ctor from another
    }
	
	
    public DShape getSelected() {
	return null;
	//		return(selected);
    }
	
    public void setSelected(DShape selected) {
	//	    if (this.selected!=null) this.selected.repaint();
	//	 	this.selected = selected;
	//	 	selected.repaint();
    }

    Random rand = new Random();


    private DMoteModel createNewMote(int moteID){
	DMoteModel m = new DMoteModel(moteID, rand, this);
	System.out.println("Adding mote " + moteID);
	motes.add(m);
	moteIndex.put(new Integer(moteID), m);
	tableModel.add(m);

	navigator.addMote(m);
	return m;
    }
    
    public void setMoteValue(int moteID, String name, int value) {
	DMoteModel m = moteIndex.get(new Integer(moteID));
	if (m == null) {
	    m = createNewMote(moteID);
	}
	System.out.println("Set " + moteID + ":" + name + " to " + value);
	m.setMoteValue(name, value);
	navigator.redrawAllLayers();
    }

    private DLinkModel createNewLink(DMoteModel start, DMoteModel end) {
	DLinkModel dl = new DLinkModel(start, end, rand, this);
	links.add(dl);
	linkIndex.put(start.getId() + " " + end.getId(), dl);
	return dl;
    }
    
    public void setLinkValue(int startMote, int endMote, String name, int value) {
	DMoteModel m = moteIndex.get(new Integer(startMote));
	if (m == null) {
	    m = createNewMote(startMote);
	}
	DMoteModel m2 = moteIndex.get(new Integer(endMote));
	if (m2 == null) {
	    m2 = createNewMote(endMote);
	}
	DLinkModel dl = linkIndex.get(startMote + " " + endMote);
	if (dl == null) {
	    dl = createNewLink(m, m2);
	}
	System.out.println("Setting " + name + " " + startMote + " -> " + endMote + " to " + value);
	dl.setLinkValue(name, value);
	navigator.redrawAllLayers();
    }
	
    // Assumes links are defined by a structure with two fields:
    /* nx_struct xxx {
       am_addr_t node;
       nx_xxx_t value;
       }
	 
       A link field must have the name link_XXXX, where X is its name.
       For example:
	 
       typedef nx_struct prr_t {
       am_addr_t node;
       nx_uint8_t prr;
       } prr_t;
	 
       typedef nx_struct routing_msg {
       prr_t link_prr;
       } routing_msg;
	 
       This will create a link field with name "prr".
    */       
	
	
    public static void usage() {
	System.err.println("usage: tos-soleil [-comm source] message_type [message_type ...]");
    }
	
    // Just a test main -- put a little DDocument on screen
    public static void main(String[] args)	{
	JFrame frame = new JFrame("MViz");
	Vector<String> packetVector = new Vector<String>();
	String source = null;
	String dir = ".";
	if (args.length > 0) {
	    for (int i = 0; i < args.length; i++) {
		if (args[i].equals("-comm")) {
		    source = args[++i];
		}
		else if (args[i].equals("-dir")) {
		    dir = args[++i];
		}
		else {
		    String className = args[i];
		    packetVector.add(className);
		}
	    }
	}
	else if (args.length != 0) {
	    usage();
	    System.exit(1);
	}
	if (packetVector.size() == 0) {
	    usage();
	    System.exit(1);
	}
	
	DataModel model = new DataModel(packetVector);
	/*Vector<String>  sm = new Vector<String>();
	    sm.add("Temperature");
	    sm.add("Humidity");
	    sm.add("Motion");
	    sm.add("Light");
	    Vector<String>  sn = new Vector<String>();
	    sn.add("Link1");
	    sn.add("Link2");
	    DDocument doc = new DDocument(600, 600, sm, sn);
	    
	*/
	DDocument doc = new DDocument(600, 600, model.fields(), model.links(), dir);
        
		frame.setContentPane(doc);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.pack();
		frame.setVisible(true);
		
		// set mote value
		/*doc.createRandomMotes();
		doc.createRandomLinks();
		doc.navigator.init();*/
		//doc.createFields();
		
		MessageInput input = new MessageInput(packetVector, source, doc);
		input.start();
    }
	
    private void repaintAllMotes(){    	
	Iterator it = motes.iterator();
	while(it.hasNext()){
	    ((DMoteModel)it.next()).requestRepaint();
	}
    }
    private void repaintAllLinks(){      	
	Iterator it = links.iterator();
	while(it.hasNext()){
	    ((DLink)it.next()).repaint();
	}
    }
    //#########################################################################//
	
	
	
    private class DrawTableModel
	extends AbstractTableModel
	implements DMoteModelListener {
	private Vector<String> fields;
	
	public DrawTableModel(Vector<String> fields) {
	    this.fields = fields;
	}
	//-----------------------------o
	public String getColumnName(int col){
	    switch(col) {
	    case 0:
		return "X";
	    case 1:
		return "Y";
	    default:
		return fields.elementAt(col - 2);
	    }
	}
	//-----------------------------o
	public int getColumnCount() { return fields.size() + 2; }
	//-----------------------------o
	public int getRowCount() {
	    return DDocument.this.motes.size();
	}	    
	//-----------------------------o
	public Object getValueAt(int row, int col) {
	    DMoteModel model = (DMoteModel) DDocument.this.motes.get(row);
	    switch(col) {
	    case 0:
		return "" + (int)model.getLocX();
	    case 1:
		return "" + (int)model.getLocY();
	    default:
		return("" + (int)model.getValue(col - 2));
	    }
	}
	//-----------------------------o
	public void shapeChanged(DMoteModel changed, int type){
	    int row = findModel(changed);
	    if (row != -1) fireTableRowsUpdated(row, row);	
	}
	//-----------------------------o
	public void add(DMoteModel model){
	    model.addListener(this);
	    int last = DDocument.this.motes.size()-1;
	    fireTableRowsInserted(last, last);
	}
	//-----------------------------o
	public void remove(DMoteModel model){
	    int row = findModel(model);
	    if (row != -1) fireTableRowsDeleted(row, row);	        
	}
	//-----------------------------o
	public void updateTable(){
	    fireTableDataChanged();
	}
	//-----------------------------o
	private int findModel(DMoteModel changed){
	    for (int i=0; i<DDocument.this.motes.size(); i++){
		if ((DMoteModel)DDocument.this.motes.get(i) == changed)
		    return i;
	    }
	    return -1;	            
			
	}
    }
    
    private class DPanel extends JPanel {
	private DNavigate nav;

	public DPanel(DNavigate n) {
	    super();
	    nav = n;
	}

	public void paintComponent(Graphics g) {
	    super.paintComponent(g);
	    setOpaque(false);
	    System.out.println("Painting panel!");
	    nav.redrawAllLayers();
	}
    }
}
