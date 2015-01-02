abstract ExtrapolationBehavior

type ExtrapError <: ExtrapolationBehavior end
function extrap_transform_x(::OnGrid, ::ExtrapError, N)
    quote
        @nexprs $N d->(1 <= x_d <= size(itp,d) || throw(BoundsError()))
    end
end
function extrap_transform_x(::OnCell, ::ExtrapError, N)
    quote
        @nexprs $N d->(.5 <= x_d <= size(itp,d) + .5 || throw(BoundsError()))
    end
end

type ExtrapNaN <: ExtrapolationBehavior end
function extrap_transform_x(::OnGrid, ::ExtrapNaN, N)
    quote
        @nexprs $N d->(1 <= x_d <= size(itp,d) || return convert(T, NaN))
    end
end
function extrap_transform_x(::OnCell, ::ExtrapNaN, N)
    quote
        @nexprs $N d->(.5 <= x_d <= size(itp,d) + .5 || return convert(T, NaN))
    end
end

type ExtrapConstant <: ExtrapolationBehavior end
function extrap_transform_x(::OnGrid, ::ExtrapConstant, N)
    quote
        @nexprs $N d->(x_d = clamp(x_d, 1, size(itp,d)))
    end
end
function extrap_transform_x(::OnCell, ::ExtrapConstant, N)
    quote
        @nexprs $N d->(x_d = clamp(x_d, .5, size(itp,d)+.5))
    end
end

type ExtrapReflect <: ExtrapolationBehavior end
function extrap_transform_x(::OnGrid, ::ExtrapReflect, N)
    quote
        @nexprs $N d->begin
            # translate x_d to inside the domain, and count the translations
            ntransl = 0
            while x_d < 1
                x_d += size(itp, d) - 1
                ntransl += 1
            end
            while x_d > size(itp, d)
                x_d -= size(itp, d) - 1
                ntransl += 1
            end

            # if odd number of translations, also reflect inside the domain
            if ntransl > 0 && mod(ntransl, 2) != 0
                x_d = size(itp, d) + 1 - x_d
            end
        end
    end
end
function extrap_transform_x(::OnCell, ::ExtrapReflect, N)
    quote
        @nexprs $N d->begin
            # translate x_d to inside the domain, and count the translations
            ntransl = 0
            while x_d < .5
                x_d += size(itp,d)
                ntransl += 1
            end
            while x_d > size(itp,d) + .5
                x_d -= size(itp,d)
                ntransl += 1
            end
            
            # if odd number of translations, also reflect inside the domain
            if ntransl > 0 && mod(ntransl, 2) != 0
                x_d = size(itp, d) + 1 - x_d
            end 
        end
    end
end

type ExtrapPeriodic <: ExtrapolationBehavior end
function extrap_transform_x(::GridRepresentation, ::ExtrapPeriodic, N)
    quote
        @nexprs $N d->begin
            # translate x_d to inside the domain
            n = convert(typeof(x_d), size(itp,d))
            while x_d < .5
                x_d += n
            end
            while x_d >= n + .5
                x_d -= n
            end
        end
    end
end

type ExtrapLinear <: ExtrapolationBehavior end
function extrap_transform_x(::OnGrid, ::ExtrapLinear, N)
    quote
        @nexprs $N d->begin
            if x_d < 1
                fx_d = x_d - convert(typeof(x_d), 1)

                k = -4*itp.coefs[1]
                return itp[1] - k * fx_d
            end
            if x_d > size(itp, d)
                s_d = size(itp,d)
                fx_d = x_d - convert(typeof(x_d), s_d)

                k = itp[s_d] - itp[s_d - 1]
                return itp[s_d] + k * fx_d
            end
        end
    end
end
extrap_transform_x(::OnCell, e::ExtrapLinear, N) = extrap_transform_x(OnGrid(), e, N)