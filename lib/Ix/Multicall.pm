package Ix::Multicall;

use Moose::Role;

requires 'execute';
requires 'call_ident';

no Moose::Role;
1;
