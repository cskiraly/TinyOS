/**
 * The virtualized collection sender abstraction.
 *
 * @author Kyle Jamieson
 * @author Philip Levis
 * @date April 25 2006
 * @see TinyOS Net2-WG
 */

#include "Collection.h"

generic configuration CollectionSenderC(collection_id_t CollectId) {
  provides {
    interface Send;
    interface Packet;
  }
}

implementation {
  components TreeCollectionC;

  Send = TreeCollectionC.Send[unique(UQ_COLLECTION_CLIENT)];
}
