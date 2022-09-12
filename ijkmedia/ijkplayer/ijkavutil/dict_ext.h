#ifndef IJKUTIL_DICT_EXT
#define IJKUTIL_DICT_EXT

int av_dict_set_intptr(AVDictionary **pm, const char *key, uintptr_t value,
                       int flags);

uintptr_t av_dict_strtoptr(char * value) ;

#endif