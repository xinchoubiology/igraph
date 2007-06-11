/* -*- mode: C -*-  */
/* 
   IGraph library.
   Copyright (C) 2003, 2004, 2005  Gabor Csardi <csardi@rmki.kfki.hu>
   MTA RMKI, Konkoly-Thege Miklos st. 29-33, Budapest 1121, Hungary
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 
   02110-1301 USA

*/

#include "memory.h"
#include "random.h"
#include "error.h"

#include <assert.h>
#include <string.h> 		/* memcpy & co. */
#include <stdlib.h>

/**
 * \ingroup dqueue
 * \brief Initializes a double ended queue (constructor).
 *
 * @return Error code:
 *         - <b>IGRAPH_ENOMEM</b>: out of memory
 */

int FUNCTION(igraph_dqueue,init) (TYPE(igraph_dqueue)* q, long int size) {
        assert(q != 0);
	if (size <= 0 ) { size=1; }
	q->stor_begin=Calloc(size, BASE);
	if (q->stor_begin==0) {
	  IGRAPH_ERROR("dqueue init failed", IGRAPH_ENOMEM);
	}
	q->stor_end=q->stor_begin + size;
	q->begin=q->stor_begin;
	q->end=NULL;
	
	return 0;
}

/**
 * \ingroup dqueue
 * \brief Destroys a double ended queue.
 */

void FUNCTION(igraph_dqueue,destroy) (TYPE(igraph_dqueue)* q) {
  assert(q != 0);
  if (q->stor_begin != 0) {
    Free(q->stor_begin);
    q->stor_begin=0;
  }
}

/**
 * \ingroup dqueue
 * \brief Decides whether the queue is empty.
 */

igraph_bool_t FUNCTION(igraph_dqueue,empty) (TYPE(igraph_dqueue)* q) {
  assert(q != 0);
  assert(q->stor_begin != 0);
  return q->end == NULL;
}

/**
 * \ingroup dqueue
 * \brief Removes all elements from the queue.
 */

void FUNCTION(igraph_dqueue,clear)   (TYPE(igraph_dqueue)* q) {
  assert(q != 0);
  assert(q->stor_begin != 0);
  q->begin=q->stor_begin;
  q->end=NULL;
}

/**
 * \ingroup dqueue
 * \brief Checks whether the queue is full.
 *
 * If a queue is full the next igraph_dqueue_push() operation will allocate
 * more memory.
 */

igraph_bool_t FUNCTION(igraph_dqueue,full) (TYPE(igraph_dqueue)* q) {
  assert(q != 0);
  assert(q->stor_begin != 0);
  return q->begin == q->end;
}

/**
 * \ingroup dqueue
 * \brief Returns the number of elements in the queue.
 */

long int FUNCTION(igraph_dqueue,size) (TYPE(igraph_dqueue)* q) {
        assert(q != 0);
        assert(q->stor_begin != 0);
	if (q->end==NULL) {
		return 0;
	} else if (q->begin < q->end) {
		return q->end - q->begin;
	} else {
		return q->stor_end - q->begin + q->end - q->stor_begin;
	}
}

/**
 * \ingroup dqueue
 * \brief Returns the element at the head of the queue.
 */

BASE FUNCTION(igraph_dqueue,head) (TYPE(igraph_dqueue)* q) {
        assert(q != 0);
	assert(q->stor_begin != 0);
	return *(q->begin);
}

/**
 * \ingroup dqueue
 * \brief Returns the element at the tail of the queue.
 */

BASE FUNCTION(igraph_dqueue,back) (TYPE(igraph_dqueue)* q) {
        assert(q != 0);
	assert(q->stor_begin != 0);
	return *(q->end-1);
}

/**
 * \ingroup dqueue
 * \brief Returns and removes the element at the head of the queue.
 */

BASE FUNCTION(igraph_dqueue,pop) (TYPE(igraph_dqueue)* q) {
	BASE tmp=*(q->begin);
        assert(q != 0);
	assert(q->stor_begin != 0);
	(q->begin)++;
	if (q->begin==q->stor_end) {
		q->begin=q->stor_begin;
	}
	if (q->begin==q->end) {
		q->end=NULL;
	}

	return tmp;
}

/**
 * \ingroup dqueue
 * \brief Returns and removes the element at the tail of the queue.
 */

BASE FUNCTION(igraph_dqueue,pop_back) (TYPE(igraph_dqueue)* q) {
	BASE tmp;
        assert(q != 0);
	assert(q->stor_begin != 0);
	if (q->end != q->stor_begin) {
		tmp=*((q->end)-1);
		q->end = (q->end)-1;
	} else {
		tmp=*((q->stor_end)-1);
		q->end = (q->stor_end)-1;
	}
	if (q->begin==q->end) {
		q->end=NULL;
	}
	
	return tmp;
}

/**
 * \ingroup dqueue
 * \brief Appends an element to the back of the queue.
 *
 * @return Error code:
 *         - <b>IGRAPH_ENOMEM</b>: out of memory
 */

int FUNCTION(igraph_dqueue,push) (TYPE(igraph_dqueue)* q, BASE elem) {
        assert(q != 0);
	assert(q->stor_begin != 0);
	if (q->begin != q->end) {
		/* not full */
		if (q->end==NULL) {
			q->end=q->begin;
		}			
		*(q->end) = elem;
		(q->end)++;
		if (q->end==q->stor_end) {
			q->end=q->stor_begin;
		}
	} else {
		/* full, allocate more storage */
		
		BASE *bigger=NULL, *old=q->stor_begin;

		bigger=Calloc( 2*(q->stor_end - q->stor_begin)+1, BASE );
		if (bigger==0) {
		  IGRAPH_ERROR("dqueue push failed", IGRAPH_ENOMEM);
		}

		if (q->stor_end - q->begin) {
			memcpy(bigger, q->begin, 
			       (q->stor_end - q->begin) * sizeof(BASE));
		}
		if (q->end - q->stor_begin > 0) {
			memcpy(bigger + (q->stor_end - q->begin),
			       q->stor_begin, (q->end - q->stor_begin) * sizeof(BASE));
		}
		
		q->end       =bigger + (q->stor_end - q->stor_begin);
		q->stor_end  =bigger + 2*(q->stor_end - q->stor_begin) + 1;
		q->stor_begin=bigger;
		q->begin     =bigger;
				
		*(q->end) = elem;
		(q->end)++;
		if (q->end==q->stor_end) {
			q->end=q->stor_begin;
		}

		Free(old);
	}
	
	return 0;
}

