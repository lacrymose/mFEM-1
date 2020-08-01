# MATLAB Programming for Finite Element Methods

## Intentions

We shall establish an iFEM-like package or a simplified version with certain extensions, named mFEM. 

- We first review the finite element methods for classical problems, including 1-D and 2-D Poisson equations, linear elasticity problems and plate bending problems, etc. 

- The basic programming style comes from iFEM. In fact, we have reconstructed the computation and assembly of the stiffness matrix and load vector step by step in the PDF document (see FEM_MATLAB_GitHub.pdf). 

-  
  **It should be pointed out that the package is only designed to help more people understand the underlying ideas in iFEM. 
   In fact, a considerable part of the program is extracted from iFEM with minor changes or simplications. See Copyright in the M-lints.**

- On this basis, we intend to develop the "variational formulation based programming"  in a similar way of FreeFEM, a high level multiphysics finite element software. The similarity here only refers to the programming style of the main program, not to the internal architecture of the software.


## Arrangement of the ongoing Toolbox 

- The toolbox has two important folders：fem and variational.

  - fem: contains all source files for solving various partial differential equations related to the revision of FEMs for the classical problems. 
    
  - variational: A new feature is the variational formulation based programming. It extends the applicaton in the fem folder.

- example: includes all the test examples corresponding to the fem folder.

- tool, mesh: You can find functions involving visulization, boundary setting, mesh generation, and numerical integration and so on.

- pdedata: It provides information of PDE equations associated with examples in the example folder. 

- meshdata: It stories mesh data used in all kinds of examples.

- matlabupdate: Some functions in the updated version of matlab are reconstructed with the same input and output. For example, contains.m ---> mycontains.m.

## Display and marking of polygonal meshes

We present some basic functions to visualize the polygonal meshes, including marking of the nodes, elements and (boundary) edges.

## Auxiliary mesh data and setboundary.m

For the convenience of computation, we introduce some auxiliary mesh data. The idea stems from the treatment of triangulation in iFEM, which is generalized to polygonal meshes with certain modifications.  

## 1-D problems

FEM1D.m and main_FEM1D.m introduce FEM programming of one dimensional problems. The assembly of stiffness matrix and load vector is explained in detail. 
The final sparse assembling index of iFEM is now replaced by 
```
ii = reshape(repmat(elem,Ndof,1), [], 1);
jj = repmat(elem(:), Ndof,1);
```

## 2-D Poisson equation
The source code of solving the 2-D Poisson equation are presented, see Poisson.m, PoissonP2.m and PoissonP3.m.

## Linear elasticity equations

For linear elasticity problems, we give a unified programming framework. Specifically, 
- The entrices of stiffness matrix are analyzed in the vectorized finite element space;
- The assembly is accomplished in the scalar FE space of each component.

We consider three forms of variational problems. 
  - The first and the second are commonly used in linear elastic problems in the form of strain and/or stress tensors. 
  - The third is just a variant of the second one with Laplacian replacing the strain tensors (named Navier form).
  - For each formulation, sparse assembling index and detailed explanation are given.

For the first two formulations,  “Neumann”  boundary conditions and Dirichlet boundary conditions are applied. 
For the third fomulation, only Dirichlet conditions are used in view of the practical problems.

## Plate bending problems

- The plate bending problem is to describe the small transverse deformation of thin plates. A special case of the equilibrium equation is the biharmonic equation, which is a typical fourth-order partial differential equation. The nonconforming element is usually applied to reduce the degrees of freedom. Among the nonconforming finite elements in two dimensional case, the Morley element is perhaps the most interesting one. It has the least number of degrees of freedom on each element for fourth order boundary value problems as its shape function space consists of only quadratic polynomials.

    It should be noted that the normal derivative values at the midpoint of interior edge sharing by two triangles have different signs. Apparently, this feature will be inherited by the corresponding local nodal basis functions given by the global ones restricted to the adjacent elements. The problem can be easily resolved by using signed edges.
    
    A more general method is added by introducing signed stiffness matrix and signed load vector. Such prodecure can be extended to other problems with d.o.f.s varing in directions and can be further applied to polygonal meshes.
	
- Besides Morley element, Zienkiewicz element and Adini element are two other commonly used nonconforming elements. 
  The former is an incomplete cubic triangular element and the latter is an incomplete bicubic rectangular element.
  In addition to directional problems, all three non-conforming elements (and conforming elements) can be programmed in the unified framework given in the document.

## Mixed FEM
  
   The mixed FEM is applied to solve the biharmonic equation, a special case of plate bending problems.
   

## Variational formulation based programming

  - A variational formulation based programming is shown for 1-D, 2-D and 3-D problems in Folder variational. The arrangement is entirely  process-oriented and thus is easy to understand. 
  
  - **As in FreeFem, fundamental functions --- int1d.m, int2d.m and int3d.m are designed to match the variational formulation of the underlying PDEs. These functions can resolve both scalar and vectorial equations (see also assem1d.m, assem2d.m and assem3d.m).**
  
  - At present, only Lagrange elements of order up to three are provided, including 1-D problems, Poisson equation, linear elasticity problem, mixed FEM of biharmonic equation and Stokes problem. 
  
  - We remark that the current design can be adapted to find FEM solutions of most of the PDE problems.
  
  - Folder variational will be integrated into iFEM in the near future.

  
## Adaptive finite element method and Newest-node bisection

The adpative finite element method (AFEM) is introduced for the Poisson equation with homogeneous Dirichlet 
   conditions.  Each step was explained in detail, viz. the loops of the form: 

           SOLVE -> ESTIMATE -> MARK -> REFINE

The newest-node bisection for the local mesh refinement was clearly stated thanks to the smart idea in iFEM.  
The MATLAB codes are in fem/afem. 

## Multigrid V-cycle method for linear elements

  - We present a multigrid method by adding two grids one by one, so that the pseudo-code of V-cycle method can be obtained directly.
  
  - The MG method can also be analyzed by using subspace correction method proposed by Xu Jinchao (for example, in iFEM). 
    However, it may be more straightforward by adding two grids.

  - The programming of 1-D problems is described in detail, and the multigrid program is universal to all linear element problems.
  
  - **For 2-D and 3-D linear elements, only slight changes of 1-D problems are needed since they can be regarded as 1-D problems.**
    See the document for details.


Undo: 

	   
            - mesh generation and optimization  
           
	       - mg V-cycle methods for 3-D problems and bisection meshes 
  
            - variational formulation programming for time-dependent problems and nonlinear poblems

            - various applications of finite element methods
	    
	    
	 
