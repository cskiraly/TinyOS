#include <sim_gain.h>

typedef struct sim_gain_noise {
  double mean;
  double range;
} sim_gain_noise_t;


gain_entry_t* connectivity[TOSSIM_MAX_NODES];
sim_gain_noise_t noise[TOSSIM_MAX_NODES];
double sensitivity = 4.0;

gain_entry_t* sim_gain_allocate_link(int mote);
void sim_gain_deallocate_link(gain_entry_t* link);

gain_entry_t* sim_gain_first(int src) __attribute__ ((C, spontaneous)) {
  return connectivity[src];
}

gain_entry_t* sim_gain_next(gain_entry_t* link) __attribute__ ((C, spontaneous)) {
  return link->next;
}

void sim_gain_add(int src, int dest, double gain) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  int temp = sim_node();
  sim_set_node(src);

  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      break;
    }
    current = current->next;
  }

  if (current == NULL) {
    current = sim_gain_allocate_link(dest);
  }
  current->mote = dest;
  current->gain = gain;
  current->next = connectivity[src];
  connectivity[src] = current;
  dbg("Binary", "Adding link from %i to %i with gain %llf\n", src, dest, gain);
  sim_set_node(temp);
}

double sim_gain_value(int src, int dest) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      return current->gain;
    }
    current = current->next;
  }
  sim_set_node(temp);
  return 1.0;
}

bool sim_gain_connected(int src, int dest) __attribute__ ((C, spontaneous)) {
  gain_entry_t* current;
  int temp = sim_node();
  sim_set_node(src);
  current = connectivity[src];
  while (current != NULL) {
    if (current->mote == dest) {
      sim_set_node(temp);
      return TRUE;
    }
    current = current->next;
  }
  sim_set_node(temp);
  return FALSE;
}
  
void sim_gain_remove(int src, int dest) __attribute__ ((C, spontaneous))  {
  gain_entry_t* current;
  gain_entry_t* prevLink;
  int temp = sim_node();
  sim_set_node(src);
    
  current = connectivity[src];
  prevLink = NULL;
    
  while (current != NULL) {
    if (current->mote == dest) {
      if (prevLink == NULL) {
	connectivity[src] = current->next;
      }
      else {
	prevLink->next = current->next;
      }
      sim_gain_deallocate_link(current);
      current = prevLink->next;
    }
    else {
      prevLink = current;
      current = current->next;
    }
  }
  sim_set_node(temp);
}

void sim_gain_set_noise_floor(int node, double mean, double range) __attribute__ ((C, spontaneous))  {
  noise[node].mean = mean;
  noise[node].range = range;
}


// Pick a number a number from the uniform distribution of
// [mean-range, mean+range].
double sim_gain_noise(int node)  __attribute__ ((C, spontaneous)) {
  double val = noise[node].mean;
  double adjust = (sim_random() % 2000000);
  adjust /= 1000000.0;
  adjust -= 1.0;
  adjust *= noise[node].range;
  return val + adjust;
}

gain_entry_t* sim_gain_allocate_link(int mote) {
  gain_entry_t* link = (gain_entry_t*)malloc(sizeof(gain_entry_t));
  link->next = NULL;
  link->mote = mote;
  link->gain = -10000000.0;
  return link;
}

void sim_gain_deallocate_link(gain_entry_t* link) {
  free(link);
}

void sim_gain_set_sensitivity(double s) {
  sensitivity = s;
}

double sim_gain_sensitivity() {
  return sensitivity;
}
