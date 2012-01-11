module sbzequations
    use double
    use environment
    use brillouin
    use scsolve
    use scsystem
    implicit none

    ! Number of self-consistent equations in the full system
    integer, parameter :: sbzNumEquations = 8

contains
    ! --- Full self-consistent system ---
    function sbzSystem(env, tolerances)
        type(Environ), intent(in) :: env
        real(kind=DP), dimension(:), allocatable :: tolerances
        type(SelfConsistentEq), dimension(:), allocatable :: equations
        type(SelfConsistentSystem) :: sbzSystem
        allocate(equations(1:8))
        equations(1) = sbzEqMuF(env)
        equations(2) = sbzEqMuB(env)
        equations(3) = sbzEqD(env)
        equations(4) = sbzEqDc(env)
        equations(5) = sbzEqB(env)
        equations(6) = sbzEqBc(env)
        equations(7) = sbzEqA(env)
        equations(8) = sbzEqAc(env)
        sbzSystem%tolerances = tolerances
        sbzSystem%equations = equations
    end function

    ! --- Self-consistent system without c-direction equations ---
    function sbzSystemNoC(env, tolerances)
        type(Environ), intent(in) :: env
        real(kind=DP), dimension(:), allocatable :: tolerances
        type(SelfConsistentEq), dimension(:), allocatable :: equations
        type(SelfConsistentSystem) :: sbzSystemNoC
        allocate(equations(1:5))
        equations(1) = sbzEqMuF(env)
        equations(2) = sbzEqMuB(env)
        equations(3) = sbzEqD(env)
        equations(4) = sbzEqB(env)
        equations(5) = sbzEqA(env)
        sbzSystemNoC%tolerances = tolerances
        sbzSystemNoC%equations = equations
    end function

    ! --- D equation ---
    function sbzEqD(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqD
        ! (Mostly) arbitrary bounds (should D be positive?).
        sbzEqD%argMin = 1e-9
        sbzEqD%argMax = 10.0 * abs(env%t)
        sbzEqD%setArg => setD
        sbzEqD%absError => absErrorD
    end function

    function absErrorD(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorD, rhs
        rhs = BrilSum(env, sumFuncD) / (env%zoneLength ** 3)
        absErrorD = env%D - rhs
    end function

    function sumFuncD(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncD
        sumFuncD = cos(k(1)) * bose(env, xiB(env, k))
    end function

    function setD(env, D)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: D
        real(kind=DP) :: setD
        setD = env%D
        env%D = D
    end function

    ! --- Dc equation ---
    function sbzEqDc(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqDc
        ! (Mostly) arbitrary bounds (should Dc be positive?).
        sbzEqDc%argMin = 1e-9
        sbzEqDc%argMax = 10.0 * abs(env%tc)
        sbzEqDc%setArg => setDc
        sbzEqDc%absError => absErrorDc
    end function

    function absErrorDc(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorDc, rhs
        rhs = BrilSum(env, sumFuncDc) / (env%zoneLength ** 3)
        absErrorDc = env%Dc - rhs
    end function

    function sumFuncDc(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncDc
        sumFuncDc = cos(k(3)) * bose(env, xiB(env, k))
    end function

    function setDc(env, Dc)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: Dc
        real(kind=DP) :: setDc
        setDc = env%Dc
        env%Dc = Dc
    end function

    ! --- B equation ---
    function sbzEqB(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqB
        ! (Mostly) arbitrary bounds (should B be positive?).
        sbzEqB%argMin = 1e-9
        sbzEqB%argMax = 10.0 * abs(env%t)
        sbzEqB%setArg => setB
        sbzEqB%absError => absErrorB
    end function

    function absErrorB(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorB, rhs
        rhs = BrilSum(env, sumFuncB) / (env%zoneLength ** 3)
        absErrorB = env%B - rhs
    end function

    function sumFuncB(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncB
        sumFuncB = 0.5_DP * cos(k(1)) * ((xiF(env, k) / bogoEnergy(env, k)) * (2.0_DP * fermi(env, xiF(env, k)) - 1.0_DP) + 1.0_DP)
    end function

    function setB(env, B)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: B
        real(kind=DP) :: setB
        setB = env%B
        env%B = B
    end function

    ! --- Bc equation ---
    function sbzEqBc(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqBc
        ! (Mostly) arbitrary bounds (should Bc be positive?).
        sbzEqBc%argMin = 1e-9
        sbzEqBc%argMax = 10.0 * abs(env%tc)
        sbzEqBc%setArg => setBc
        sbzEqBc%absError => absErrorBc
    end function

    function absErrorBc(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorBc, rhs
        rhs = BrilSum(env, sumFuncBc) / (env%zoneLength ** 3)
        absErrorBc = env%Bc - rhs
    end function

    function sumFuncBc(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncBc
        sumFuncBc = 0.5_DP * cos(k(3)) * ((xiF(env, k) / bogoEnergy(env, k)) * (2.0_DP * fermi(env, xiF(env, k)) - 1.0_DP) + 1.0_DP)
    end function

    function setBc(env, Bc)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: Bc
        real(kind=DP) :: setBc
        setBc = env%Bc
        env%Bc = Bc
    end function

    ! --- A equation ---
    function sbzEqA(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqA
        ! (Mostly) arbitrary bounds (should A be positive?).
        sbzEqA%argMin = 1e-9
        sbzEqA%argMax = 10.0 * abs(env%J)
        sbzEqA%setArg => setA
        sbzEqA%absError => absErrorA
    end function

    function absErrorA(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorA, rhs
        rhs = BrilSum(env, sumFuncA) / (env%zoneLength ** 3)
        absErrorA = env%A - rhs
    end function

    function sumFuncA(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncA
        sumFuncA = 0.5_DP * cos(k(1)) * (Delta(env, k) / bogoEnergy(env, k)) * (2.0_DP * fermi(env, xiF(env, k)) - 1.0_DP)
    end function

    function setA(env, A)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: A
        real(kind=DP) :: setA
        setA = env%A
        env%A = A
    end function

    ! --- Ac equation ---
    function sbzEqAc(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqAc
        ! (Mostly) arbitrary bounds (should Ac be positive?).
        sbzEqAc%argMin = 1e-9
        sbzEqAc%argMax = 10.0 * abs(Jc(env))
        sbzEqAc%setArg => setAc
        sbzEqAc%absError => absErrorAc
    end function

    function absErrorAc(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorAc, rhs
        rhs = BrilSum(env, sumFuncAc) / (env%zoneLength ** 3)
        absErrorAc = env%Ac - rhs
    end function

    function sumFuncAc(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncAc
        sumFuncAc = 0.5_DP * cos(k(3)) * (Delta(env, k) / bogoEnergy(env, k)) * (2.0_DP * fermi(env, xiF(env, k)) - 1.0_DP)
    end function

    function setAc(env, Ac)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: Ac
        real(kind=DP) :: setAc
        setAc = env%Ac
        env%Ac = Ac
    end function

    ! --- muB equation ---
    function sbzEqMuB(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqMuB
        ! (Mostly) arbitrary bounds (muB must be negative and nonzero).
        sbzEqMuB%argMin = -10.0 * abs(env%t)
        sbzEqMuB%argMax = -1e-9
        sbzEqMuB%setArg => setMuB
        sbzEqMuB%absError => absErrorMuB
    end function

    function absErrorMuB(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorMuB, rhs
        rhs = BrilSum(env, sumFuncMuB) / (env%zoneLength ** 3)
        absErrorMuB = env%x - rhs
    end function

    function sumFuncMuB(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncMuB
        sumFuncMuB = bose(env, xiB(env, k))
    end function

    function setMuB(env, muB)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: muB
        real(kind=DP) :: setMuB
        setMuB = env%muB
        env%muB = muB
    end function

    ! --- muF equation ---
    function sbzEqMuF(env)
        type(Environ), intent(in) :: env
        type(SelfConsistentEq) :: sbzEqMuF
        ! (Mostly) arbitrary bounds (muF must be positive and nonzero).
        sbzEqMuF%argMin = 10.0 * abs(env%t)
        sbzEqMuF%argMax = 1e-9
        sbzEqMuF%setArg => setMuF
        sbzEqMuF%absError => absErrorMuF
    end function

    function absErrorMuF(env)
        type(Environ), intent(in) :: env
        real(kind=DP) :: absErrorMuF, rhs
        rhs = BrilSum(env, sumFuncMuF) / (env%zoneLength ** 3)
        absErrorMuF = 1.0_DP - env%x - rhs
    end function

    function sumFuncMuF(env, k)
        type(Environ), intent(in) :: env
        real(kind=DP), intent(in) :: k(1:3)
        real(kind=DP) :: sumFuncMuF
        sumFuncMuF = (xiF(env, k) / bogoEnergy(env, k)) * (2.0_DP * fermi(env, xiF(env, k)) - 1.0_DP) + 1.0_DP
    end function

    function setMuF(env, muF)
        type(Environ), intent(inout) :: env
        real(kind=DP), intent(in) :: muF
        real(kind=DP) :: setMuF
        setMuF = env%muF
        env%muF = muF
    end function
end module
