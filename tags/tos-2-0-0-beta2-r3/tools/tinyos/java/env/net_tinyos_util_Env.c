// $Id: net_tinyos_util_Env.c,v 1.1.2.1 2005-07-26 17:15:25 idgay Exp $

#include "net_tinyos_util_Env.h"
#include <stdlib.h>


JNIEXPORT jstring JNICALL Java_net_tinyos_util_Env_igetenv
  (JNIEnv *env, jclass c, jstring jname)
{
  const char *name, *value;

  if (jname == NULL)
    return NULL;

  name = (*env)->GetStringUTFChars(env, jname, (jboolean *)NULL);

  value = getenv(name) ;

  (*env)->ReleaseStringUTFChars(env, jname, name);

  return value ? (*env)->NewStringUTF(env, value) : NULL;
}
