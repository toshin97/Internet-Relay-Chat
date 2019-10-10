#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "linked-list.h"


/* Constants */
#define TRUE 1
#define FALSE 0



/* LinkedList */

/**
 * Initialze a linked list.
 * This function be called once and only once before a linked list
 * may be used.
 */
void init_list(LinkedList* list)
{
    list->head = NULL;
    list->tail = NULL;
    list->size = 0;
    list->__count = 0;
}



/**
 * Add an item, pointed to by |data|, to a linked list.
 */
Node* add_item(LinkedList* list, void* data)
{
    // Allocate a new node
    Node* node = malloc(sizeof(Node));
    node->data = data;
    node->prev = NULL;
    node->next = NULL;
    node->__id = list->__count;
    
    // Adding to an empty list
    if (list->head == NULL)
    {
        list->head = node;
        list->tail = node;
    }
    // At least one elements => Insert at head
    else
    {
        node->next = list->head;
        list->head->prev = node;
        list->head = node;
    }
    list->size += 1;
    list->__count += 1;
    return node;
}



/**
 * Drop a node from a linked list.
 */
void* drop_node(LinkedList* list, Node* node)
{
    void* data = node->data;
    // Fix link
    // |node| wasn't head
    if (node->prev != NULL)
        node->prev->next = node->next;
    // |node| was head => head now points to the next node
    else
        list->head = node->next;
    // |node| wasn't tail
    if (node->next != NULL)
        node->next->prev = node->prev;
    // |node| was tail => tail now points to the previous node
    else
        list->tail = node->prev;
    // Free memory
    free(node);
    list->size -= 1;
    return data;
}



/**
 * Convert a list to string and store it in the input buffer.
 */
char* list_to_str(LinkedList* list, char* buf)
{
    *buf++ = '[';
    for (Node* node = list->head; node != NULL; node = node->next)
    {
        if (node != list->head)
            buf += sprintf(buf, ", ");
        
        buf += sprintf(buf, "%i", node->__id);
    }
    *buf++ = ']';
    *buf++ = '\0';
    return buf;
}



/* Iterator_LinkedList */

/**
 * Obtain an iterator for the linked list |list|.
 */
Iterator_LinkedList* iter(LinkedList* list)
{
    Iterator_LinkedList* it = malloc(sizeof(Iterator_LinkedList));
    it->list = list;
    it->curr = list->head;
    it->yielded = FALSE;
    return it;
}



/**
 * Check if an iterator contains any more node.
 */
int iter_empty(Iterator_LinkedList* it)
{
    return it->curr == NULL;
}



/**
 * Get the next iterator.
 * To be used only in a for loop:
        for (Iterator_LinkedList* it = iter(&l);
            !iter_empty(it);
            it = iter_next(it))
        { // Your code here }
 */
Iterator_LinkedList* iter_next(Iterator_LinkedList* it)
{
    if (!it->yielded)
        iter_yield(it);
    else
        it->yielded = FALSE;
    return it;
}



/**
 * Add an item, pointed to by |data|, to the list referred to by the iterator.
 */
Node* iter_add(Iterator_LinkedList* it, void* data)
{
    return add_item(it->list, data);
}



/**
 * Drop the current item from an iterator.
 */
void* iter_drop(Iterator_LinkedList* it)
{
    Node* to_be_dropped = it->curr;
    iter_yield(it);
    return drop_node(it->list, to_be_dropped);
}



/**
 * Drop a node item from the list referred to by the iterator.
 */
void* iter_drop_node(Iterator_LinkedList* it, Node* node)
{
    if (node == it->curr)
        return iter_drop(it);
    else
        return drop_node(it->list, node);
}



/**
 * Yield the current item from the iterator.
 * Note: this function will increment the pointer, so the same node
 * will never be yielded twice.
 */
void* iter_yield(Iterator_LinkedList* it)
{
    assert(!it->yielded);
    it->yielded = TRUE;
    Node* curr = it->curr;
    it->curr = it->curr->next;
    return curr->data;
}
