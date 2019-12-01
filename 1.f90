! compiled with gfortran

program main    
    integer, dimension(100) :: masses
    integer i

    length = 100
    open (10, FILE="inputs/1")
    read (10, *)  (masses(i), i = 1, length)
    write(*, *) solve1(masses, length)
    write(*, *) solve2(masses, length)
contains
    integer function solve1 (masses, n)
        integer, intent(in) :: n
        integer, intent(in) :: masses(n)
        integer i, fuel, sum

        sum = 0
        do i = 1, n
            fuel = masses(i) / 3 - 2
            sum = sum + fuel
        end do
        solve1 = sum
    end function solve1
    integer function solve2 (masses, n)
        integer, intent(in) :: n
        integer, intent(in) :: masses(n)
        integer i, fuel, sum

        sum = 0
        do i = 1, n
            fuel = masses(i) / 3 - 2
            do while (fuel > 0)
                sum = sum + fuel
                fuel = fuel / 3 - 2
            end do
        end do
        solve2 = sum
    end function solve2
end program